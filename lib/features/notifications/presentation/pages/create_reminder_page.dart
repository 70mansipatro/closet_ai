import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/notifications/application/notification_providers.dart';
import 'package:closet_ai/features/notifications/domain/reminder_model.dart';
import 'package:closet_ai/widgets/gradient_button.dart';

const _typeLabels = {
  'CUSTOM': 'Custom',
  'OUTFIT_REMINDER': 'Outfit',
  'LAUNDRY_REMINDER': 'Laundry',
  'TRIP_REMINDER': 'Trip',
  'PACKING_REMINDER': 'Packing',
  'WEAR_HISTORY_REMINDER': 'Wear history',
  'WARDROBE_REMINDER': 'Wardrobe',
  'AI_STYLIST_REMINDER': 'AI Stylist',
  'SUBSCRIPTION_REMINDER': 'Subscription',
};

class CreateReminderPage extends ConsumerStatefulWidget {
  const CreateReminderPage({super.key});

  @override
  ConsumerState<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends ConsumerState<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'CUSTOM';
  String _frequency = 'once';
  String _priority = 'normal';
  int _snoozeMinutes = 15;
  bool _smartEnabled = false;
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final scheduledDateTime = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
      final payload = ReminderModel(
        id: '',
        type: _type,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        enabled: true,
        frequency: _frequency,
        scheduledTime:
            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
        daysOfWeek: const [],
        date: _frequency == 'once' ? scheduledDateTime : null,
        priority: _priority,
        snoozeMinutes: _snoozeMinutes,
        smartEnabled: _smartEnabled,
        nextTriggerAt: null,
        lastTriggeredAt: null,
      ).toCreatePayload();

      await ref.read(notificationRepositoryProvider).createReminder(payload);
      await ref.read(localNotificationSyncServiceProvider).sync();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save reminder: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Reminder')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Reminder type'),
              items: reminderTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabels[t] ?? t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                    onTap: _pickDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time'),
                    subtitle: Text(_time.format(context)),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: reminderFrequencies
                  .where((f) => f != 'smart')
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _frequency = v ?? _frequency),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: reminderPriorities
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v ?? _priority),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _snoozeMinutes,
              decoration: const InputDecoration(labelText: 'Default snooze duration'),
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 minutes')),
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 60, child: Text('1 hour')),
              ],
              onChanged: (v) => setState(() => _snoozeMinutes = v ?? _snoozeMinutes),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.blueViolet,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 20),
              ),
              title: const Text('Smart reminder'),
              subtitle: const Text('Let ClosetAI adjust timing based on your activity'),
              value: _smartEnabled,
              onChanged: (v) => setState(() => _smartEnabled = v),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    label: 'Save Reminder',
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
