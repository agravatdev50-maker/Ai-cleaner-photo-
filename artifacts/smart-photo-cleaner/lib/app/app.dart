import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../presentation/providers/theme_provider.dart';
import 'router.dart';

/// Root application widget.
/// Reads theme preference from [themeProvider] and applies Material 3 theming.
class SmartPhotoCleanerApp extends ConsumerWidget {
  const SmartPhotoCleanerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Smart Photo Cleaner',
      debugShowCheckedModeBanner: false,

      // Material 3 enabled
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // GoRouter handles navigation
      routerConfig: router,
    );
  }
}
