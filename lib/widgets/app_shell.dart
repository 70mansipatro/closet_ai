import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/layout/app_layout.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _navItems = [
  _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Analytics'),
  _NavItem(Icons.checkroom_outlined, Icons.checkroom, 'Wardrobe'),
  _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI'),
  _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Stylist'),
  _NavItem(Icons.person_outline, Icons.person, 'Profile'),
];

/// Hosts the persistent ClosetAI navigation chrome around every tab screen.
///
/// - Phone/tablet widths: a fixed bottom [NavigationBar] that never scrolls
///   away, with [resizeToAvoidBottomInset] disabled so the nav chrome stays
///   put when a keyboard opens on a nested screen — the nested screen's own
///   Scaffold is left to resize its own body around the keyboard instead of
///   the whole shell (including the nav bar) sliding up.
/// - Desktop/web widths: a side [NavigationRail], matching the pattern
///   already used by AdminShell, so the app doesn't force a mobile-style
///   bottom bar onto large screens.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final selected = _selectedIndex(currentPath);

    if (AppLayout.isDesktop(context)) {
      final railTheme = Theme.of(context).navigationRailTheme;
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 124,
              color: railTheme.backgroundColor,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var i = 0; i < _navItems.length; i++)
                            _RailItem(
                              item: _navItems[i],
                              selected: i == selected,
                              unselectedColor: railTheme.unselectedIconTheme?.color,
                              onTap: () => _goTo(context, i),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 2, decoration: const BoxDecoration(gradient: AppGradients.primary)),
          NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (index) => _goTo(context, index),
            destinations: [
              for (final item in _navItems)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
            ],
          ),
        ],
      ),
    );
  }

  int _selectedIndex(String path) {
    if (path.startsWith('/analytics')) return 1;
    if (path.startsWith('/wardrobe')) return 2;
    if (path.startsWith('/ai/stylist')) return 4;
    if (path.startsWith('/ai')) return 3;
    if (path.startsWith('/profile')) return 5;
    return 0;
  }

  void _goTo(BuildContext context, int index) {
    switch (index) {
      case 1:
        context.go('/analytics');
        break;
      case 2:
        context.go('/wardrobe');
        break;
      case 3:
        context.go('/ai');
        break;
      case 4:
        context.go('/ai/stylist');
        break;
      case 5:
        context.go('/profile');
        break;
      default:
        context.go('/dashboard');
    }
  }
}

/// One destination in the desktop sidebar: an icon badge (gradient-filled
/// when selected) stacked above its label, matching the rounded-square
/// selection style from the app's brand identity.
class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.selected,
    required this.unselectedColor,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final Color? unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: selected ? AppGradients.primary : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: selected ? Colors.white : unselectedColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.cyan : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
