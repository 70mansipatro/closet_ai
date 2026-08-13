import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/gradient_button.dart';
import '../../application/wardrobe_state.dart';

const List<String> wearOccasions = [
  'Casual',
  'Work',
  'Party',
  'Date',
  'Travel',
  'Workout',
  'Dinner',
  'Other',
];

/// Opens the "Mark as Worn" bottom sheet for [itemId]. Resolves with the
/// [WardrobeMarkWornResult] on success, or null if the user dismissed it.
Future<WardrobeMarkWornResult?> showMarkAsWornSheet(
  BuildContext context, {
  required String itemId,
}) {
  return showModalBottomSheet<WardrobeMarkWornResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _MarkAsWornSheet(itemId: itemId),
  );
}

class _MarkAsWornSheet extends ConsumerStatefulWidget {
  const _MarkAsWornSheet({required this.itemId});

  final String itemId;

  @override
  ConsumerState<_MarkAsWornSheet> createState() => _MarkAsWornSheetState();
}

class _MarkAsWornSheetState extends ConsumerState<_MarkAsWornSheet> {
  String _occasion = wearOccasions.first;
  int _rating = 0;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final result = await ref
          .read(wardrobeControllerProvider.notifier)
          .markAsWorn(
            id: widget.itemId,
            occasion: _occasion,
            rating: _rating > 0 ? _rating : null,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this wear. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How did you wear this?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Text('Occasion', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: wearOccasions
                    .map(
                      (value) => ChoiceChip(
                        label: Text(value),
                        selected: _occasion == value,
                        onSelected: (_) => setState(() => _occasion = value),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text('Rating', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final filled = starValue <= _rating;
                  return IconButton(
                    onPressed: () => setState(
                      () => _rating = _rating == starValue ? 0 : starValue,
                    ),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: filled ? AppColors.gold : null,
                      size: 30,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. Felt comfortable',
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: _isSubmitting ? 'Saving…' : 'Save Wear',
                icon: Icons.checkroom_rounded,
                loading: _isSubmitting,
                onPressed: _isSubmitting ? null : _save,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
