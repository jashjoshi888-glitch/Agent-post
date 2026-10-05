import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/brand_kit/presentation/brand_kit_screen.dart';
import '../../features/create/presentation/create_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/application/profile_controller.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/main_shell.dart';

/// Listens to login/profile changes and tells the router to re-check the
/// navigation rules (so the app reacts instantly to sign-in / sign-out).
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
    _ref.listen(profileProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  /// The navigation rules of the app, in one place:
  ///  * signed out  → only the login/signup/forgot-password screens.
  ///  * signed in but profile not completed yet → onboarding.
  ///  * signed in and profile completed → the main app.
  String? redirect(BuildContext context, GoRouterState state) {
    final user = _ref.read(authControllerProvider);
    final location = state.matchedLocation;

    const authScreens = ['/login', '/signup', '/forgot-password'];
    final isAuthScreen = authScreens.contains(location);

    if (user == null) {
      return isAuthScreen ? null : '/login';
    }

    // Signed in. When the profile has not loaded yet, stay where we are —
    // the listener above re-runs these rules the moment it arrives.
    final profile = _ref.read(profileProvider).valueOrNull;
    if (profile == null) {
      return isAuthScreen ? '/' : null;
    }

    final onboardingDone = profile.onboardingCompleted;
    if (!onboardingDone && location != '/onboarding') {
      return '/onboarding';
    }
    if (onboardingDone && (location == '/onboarding' || isAuthScreen)) {
      return '/';
    }
    return null;
  }
}

/// The app's route table.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/brand-kit',
        builder: (context, state) => const BrandKitScreen(),
      ),
      // Main app shell with the bottom navigation bar (Home, Create,
      // Customers, Profile). Each tab keeps its own navigation state.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/create',
              builder: (context, state) => const CreateScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/customers',
              builder: (context, state) => const CustomersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
