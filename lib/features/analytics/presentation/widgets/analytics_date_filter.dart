import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One selectable date-range option. [value] must match one of the raw
/// string filter values already understood by `analyticsFilterProvider`
/// consumers (see AnalyticsPage._applyFilter) — this widget only renders
/// selection state, it does not know about filter semantics.
class AnalyticsDateFilterOption {
  const AnalyticsDateFilterOption(this.label, this.value);
  final String label;
  final String value;
}

const List<AnalyticsDateFilterOption> analyticsDateFilterOptions = [
  AnalyticsDateFilterOption('Today', 'today'),
  AnalyticsDateFilterOption('Week', 'this_week'),
  AnalyticsDateFilterOption('Month', 'this_month'),
  AnalyticsDateFilterOption('30 Days', '30_days'),
  AnalyticsDateFilterOption('3M', '3_months'),
  AnalyticsDateFilterOption('6M', '6_months'),
  AnalyticsDateFilterOption('Year', 'this_year'),
];

/// Horizontal, scrollable pill selector for the analytics date range. Purely
/// presentational — the page owns `_dateFilter` and the actual provider
/// update logic, this widget just reports taps via [onChanged].
class AnalyticsDateFilter extends StatelessWidget {
  const AnalyticsDateFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: analyticsDateFilterOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = analyticsDateFilterOptions[index];
          final selected = option.value == value;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected ? AppColors.purple : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.purple
                    : colorScheme.outline,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(option.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Center(
                    child: Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
