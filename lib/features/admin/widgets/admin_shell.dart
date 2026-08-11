import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_state.dart';

class _AdminNavItem {
  const _AdminNavItem(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}

const _navItems = [
  _AdminNavItem('/admin/dashboard', Icons.dashboard_outlined, 'Dashboard'),
  _AdminNavItem('/admin/users', Icons.people_outline, 'Users'),
  _AdminNavItem(
    '/admin/subscriptions',
    Icons.card_membership_outlined,
    'Subscriptions',
  ),
  _AdminNavItem('/admin/plans', Icons.workspace_premium_outlined, 'Plans'),
  _AdminNavItem('/admin/payments', Icons.payments_outlined, 'Payments'),
  _AdminNavItem('/admin/revenue', Icons.trending_up_outlined, 'Revenue'),
  _AdminNavItem('/admin/analytics', Icons.insights_outlined, 'Analytics'),
  _AdminNavItem('/admin/reports', Icons.description_outlined, 'Reports'),
  _AdminNavItem('/admin/audit-logs', Icons.fact_check_outlined, 'Audit Logs'),
  _AdminNavItem('/admin/notifications', Icons.campaign_outlined, 'Notifications'),
  _AdminNavItem('/admin/settings', Icons.settings_outlined, 'Settings'),
  _AdminNavItem('/admin/profile', Icons.admin_panel_settings_outlined, 'Profile'),
];

int _selectedIndex(String path) {
  var bestIndex = 0;
  var bestLength = -1;
  for (var i = 0; i < _navItems.length; i++) {
    final itemPath = _navItems[i].path;
    if (path.startsWith(itemPath) && itemPath.length > bestLength) {
      bestIndex = i;
      bestLength = itemPath.length;
    }
  }
  return bestIndex;
}

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).matchedLocation;
    final selected = _selectedIndex(path);
    final isWide = MediaQuery.of(context).size.width >= 900;
    final auth = ref.watch(authControllerProvider);
    final adminName = auth.user?['name']?.toString() ?? 'Admin';

    void onSelect(int index) => context.go(_navItems[index].path);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      child: Text(adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A'),
                    ),
                    const SizedBox(height: 4),
                    Text('ClosetAI Admin', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              destinations: [
                for (final item in _navItems)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      tooltip: 'Exit Admin Panel',
                      icon: const Icon(Icons.logout),
                      onPressed: () => context.go('/dashboard'),
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[selected].label),
        actions: [
          IconButton(
            tooltip: 'Exit Admin Panel',
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  CircleAvatar(
                    child: Text(adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A'),
                  ),
                  const SizedBox(width: 12),
                  Text('ClosetAI Admin', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            for (var i = 0; i < _navItems.length; i++)
              ListTile(
                leading: Icon(_navItems[i].icon),
                title: Text(_navItems[i].label),
                selected: i == selected,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(i);
                },
              ),
          ],
        ),
      ),
      body: child,
    );
  }
}
