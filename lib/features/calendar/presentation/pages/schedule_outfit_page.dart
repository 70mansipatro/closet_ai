import 'package:closet_ai/features/calendar/data/calendar_repository.dart';
import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/widgets/gradient_button.dart';
import 'package:flutter/material.dart';

class ScheduleOutfitPage extends StatefulWidget {
  const ScheduleOutfitPage({super.key});

  @override
  State<ScheduleOutfitPage> createState() => _ScheduleOutfitPageState();
}

class _ScheduleOutfitPageState extends State<ScheduleOutfitPage> {
  final _dateController = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    final repo = CalendarRepository(ApiClient());
    final payload = {'date': _dateController.text};
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.schedule(payload: payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to schedule: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Outfit')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date (ISO)'),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Save',
              icon: Icons.event_available_rounded,
              loading: _loading,
              onPressed: _loading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
