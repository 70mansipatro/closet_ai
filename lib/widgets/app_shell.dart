import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(currentPath),
        onDestinationSelected: (index) => _goTo(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            label: 'Wardrobe',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Stylist',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
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
