import 'package:closet_ai/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const _MarkerScreen(),
          ),
        ],
      ),
    ],
  );
}

class _MarkerScreen extends StatelessWidget {
  const _MarkerScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: const [
          SizedBox(height: 2000, child: Center(child: Text('marker-content'))),
        ],
      ),
    );
  }
}

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp.router(routerConfig: _buildTestRouter()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone width shows a fixed NavigationBar with all 6 destinations', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(400, 800));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Wardrobe'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Stylist'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('phone width does not resize the shell scaffold when keyboard insets change', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(400, 800));

    final shellScaffoldFinder = find.byType(Scaffold).first;
    final scaffold = tester.widget<Scaffold>(shellScaffoldFinder);
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
    expect(scaffold.bottomNavigationBar, isNotNull);
  });

  testWidgets('desktop width shows a NavigationRail instead of a bottom bar', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1200, 800));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('body content is laid out above the bottom nav bar, not behind it', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(400, 800));

    final navBarTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
    final bodyBottomEdge = tester.getBottomLeft(find.byType(ListView)).dy;

    expect(
      bodyBottomEdge,
      lessThanOrEqualTo(navBarTop + 0.5),
      reason: 'ListView body must be constrained to the area above the NavigationBar',
    );
  });
}
