import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/router.dart';

/// Splash / onboarding screen shown on first launch.
/// Requests gallery permission and then navigates to the dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;
  bool _denied   = false;

  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    // Brief delay so the splash animation plays
    await Future.delayed(const Duration(milliseconds: 1800));

    final status = await _requestPermission();

    if (!mounted) return;

    if (status) {
      context.go(AppRoutes.dashboard);
    } else {
      setState(() {
        _checking = false;
        _denied   = true;
      });
    }
  }

  Future<bool> _requestPermission() async {
    // Android 13+: READ_MEDIA_IMAGES; Android 10–12: READ_EXTERNAL_STORAGE
    PermissionStatus status;
    if (await Permission.photos.isGranted) return true;

    status = await Permission.photos.request();
    if (status.isGranted) return true;

    // Try legacy permission for older Android
    status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _openSettings() async {
    await openAppSettings();
    if (!mounted) return;
    setState(() {
      _checking = true;
      _denied   = false;
    });
    await _checkAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: _denied ? _buildDeniedView(cs, tt) : _buildSplashView(cs, tt),
        ),
      ),
    );
  }

  Widget _buildSplashView(ColorScheme cs, TextTheme tt) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.3),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.auto_awesome_rounded, size: 60, color: cs.primary),
        )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .fade(duration: 400.ms),

        const SizedBox(height: 32),

        Text(
          'Smart Photo Cleaner',
          style: tt.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        )
            .animate(delay: 300.ms)
            .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut)
            .fade(duration: 400.ms),

        const SizedBox(height: 12),

        Text(
          'AI-powered photo management\n100% on-device • Never uploads your photos',
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        )
            .animate(delay: 500.ms)
            .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut)
            .fade(duration: 400.ms),

        const SizedBox(height: 60),

        if (_checking)
          CircularProgressIndicator(color: cs.primary)
              .animate(delay: 700.ms)
              .fade(duration: 300.ms),
      ],
    );
  }

  Widget _buildDeniedView(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: cs.error)
              .animate()
              .shake(duration: 600.ms),

          const SizedBox(height: 24),

          Text(
            'Gallery Access Required',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          Text(
            'Smart Photo Cleaner needs access to your photos to find '
            'duplicates and analyze quality. All processing happens '
            'locally on your device.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Open Settings'),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: _checkAndNavigate,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
