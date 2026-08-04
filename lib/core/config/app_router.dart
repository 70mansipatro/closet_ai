import 'package:go_router/go_router.dart';

import '../../features/ai/presentation/pages/ai_home_page.dart';
import '../../features/ai/presentation/pages/ai_page.dart';
import '../../features/ai/presentation/pages/favorite_outfits_page.dart';
import '../../features/ai/presentation/pages/saved_outfits_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/profile_setup_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/laundry/presentation/pages/laundry_page.dart';
import '../../features/packing/presentation/pages/packing_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/trip/presentation/pages/trip_page.dart';
import '../../features/wardrobe/domain/wardrobe_item.dart';
import '../../features/wardrobe/presentation/pages/wardrobe_form_page.dart';
import '../../features/wardrobe/presentation/pages/wardrobe_page.dart';
import '../../widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final email = state.extra as String? ?? '';
        return OtpVerificationPage(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final payload = state.extra as Map<String, dynamic>? ?? {};
        return ResetPasswordPage(
          email: payload['email'] as String? ?? '',
          otp: payload['otp'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/wardrobe',
          builder: (context, state) => const WardrobePage(),
        ),
        GoRoute(
          path: '/wardrobe/form',
          builder: (context, state) {
            WardrobeItem? item;
            String? initialCategory;

            final extra = state.extra;
            if (extra is WardrobeItem) {
              item = extra;
            } else if (extra is Map) {
              if (extra['item'] is WardrobeItem) {
                item = extra['item'] as WardrobeItem;
              }
              if (extra['category'] != null) {
                initialCategory = extra['category'].toString();
              }
            }

            return WardrobeFormPage(
              item: item,
              initialCategory: initialCategory,
            );
          },
        ),
        GoRoute(path: '/ai', builder: (context, state) => const AiHomePage()),
        GoRoute(
          path: '/ai/generate',
          builder: (context, state) => const AiPage(),
        ),
        GoRoute(
          path: '/ai/saved',
          builder: (context, state) => const SavedOutfitsPage(),
        ),
        GoRoute(
          path: '/ai/favorites',
          builder: (context, state) => const FavoriteOutfitsPage(),
        ),
        GoRoute(path: '/trips', builder: (context, state) => const TripPage()),
        GoRoute(
          path: '/packing',
          builder: (context, state) => const PackingPage(),
        ),
        GoRoute(
          path: '/laundry',
          builder: (context, state) => const LaundryPage(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarPage(),
        ),
        GoRoute(
          path: '/subscription',
          builder: (context, state) => const SubscriptionPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);
