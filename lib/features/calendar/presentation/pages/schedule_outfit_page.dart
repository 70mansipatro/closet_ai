import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/calendar/data/calendar_repository.dart';
import 'package:closet_ai/widgets/gradient_button.dart';
import 'package:closet_ai/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleOutfitPage extends StatefulWidget {
  const ScheduleOutfitPage({super.key, this.outfitId, this.initialOccasion, this.initialNotes});

  final String? outfitId;
  final String? initialOccasion;
  final String? initialNotes;

  @override
  State<ScheduleOutfitPage> createState() => _ScheduleOutfitPageState();
}

class _ScheduleOutfitPageState extends State<ScheduleOutfitPage> {
  final _dateFormat = DateFormat('EEEE, d MMM yyyy');
  late DateTime _date;
  late TimeOfDay _time;
  late final TextEditingController _occasionController;
  late final TextEditingController _notesController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _time = TimeOfDay.now();
    _occasionController = TextEditingController(text: widget.initialOccasion ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _occasionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final repo = CalendarRepository(ApiClient());
    final dateOnly = DateTime.utc(_date.year, _date.month, _date.day);
    final payload = <String, dynamic>{
      'date': dateOnly.toIso8601String(),
      'time': _time.format(context),
      if (widget.outfitId != null) 'outfitId': widget.outfitId,
      if (_occasionController.text.trim().isNotEmpty) 'occasion': _occasionController.text.trim(),
      if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
    };
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.schedule(payload: payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to schedule: ${ApiClient.extractErrorMessage(error)}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Outfit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                title: 'When',
                icon: Icons.event_outlined,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(_dateFormat.format(_date)),
                      trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_outlined),
                      title: Text(_time.format(context)),
                      trailing: TextButton(onPressed: _pickTime, child: const Text('Change')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Details',
                icon: Icons.notes_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _occasionController,
                      decoration: const InputDecoration(labelText: 'Occasion'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Save',
                icon: Icons.event_available_rounded,
                loading: _loading,
                onPressed: _loading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
