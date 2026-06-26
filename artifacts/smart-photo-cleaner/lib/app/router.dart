import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/scanner_screen.dart';
import '../presentation/screens/photo_groups_screen.dart';
import '../presentation/screens/photo_viewer_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/help_screen.dart';
import '../presentation/screens/about_screen.dart';
import '../presentation/screens/delete_review_screen.dart';

/// Route name constants — use these instead of raw strings.
class AppRoutes {
  static const splash = '/';
  static const dashboard = '/dashboard';
  static const scanner = '/scanner';
  static const photoGroups = '/groups';
  static const photoViewer = '/viewer';
  static const deleteReview = '/delete-review';
  static const settings = '/settings';
  static const help = '/help';
  static const about = '/about';
}

/// Riverpod provider for the GoRouter instance.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanner,
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.photoGroups,
        builder: (context, state) {
          // Pass category filter via query param (e.g. ?category=duplicates)
          final category = state.uri.queryParameters['category'] ?? 'all';
          final title = state.uri.queryParameters['title'] ?? 'Similar Photos';
          return PhotoGroupsScreen(category: category, title: title);
        },
      ),
      GoRoute(
        path: AppRoutes.photoViewer,
        builder: (context, state) {
          // Safe cast — extra may be null on deep-links or malformed pushes.
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text('Photo viewer requires a valid group context.')),
            );
          }
          return PhotoViewerScreen(
            groupId:      extra['groupId'] as String? ?? '',
            initialIndex: extra['initialIndex'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.deleteReview,
        builder: (context, state) => const DeleteReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
    ],

    // Custom error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
