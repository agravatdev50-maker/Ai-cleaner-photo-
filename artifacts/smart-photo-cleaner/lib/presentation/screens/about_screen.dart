import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About screen — app info, credits, and tech stack.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── App icon ─────────────────────────────────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 52, color: cs.primary),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fade(duration: 400.ms),

            const SizedBox(height: 20),

            Text('Smart Photo Cleaner',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700))
                .animate(delay: 200.ms).fade(duration: 400.ms).slideY(begin: 0.2, end: 0),

            Text('Version $_version',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                .animate(delay: 300.ms).fade(duration: 400.ms),

            const SizedBox(height: 32),

            // ── Privacy statement ────────────────────────────────────────
            _InfoCard(
              icon: Icons.lock_rounded,
              iconColor: Colors.green,
              title: 'Privacy First',
              body: 'All photo analysis happens entirely on your device. '
                  'No photos, metadata, or personal data is ever uploaded '
                  'to any server. Smart Photo Cleaner works fully offline.',
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 12),

            // ── Tech stack ───────────────────────────────────────────────
            _InfoCard(
              icon: Icons.code_rounded,
              iconColor: cs.primary,
              title: 'Technology',
              body: '• Flutter 3 + Material 3\n'
                  '• Riverpod state management\n'
                  '• Google ML Kit — Face Detection & Image Labeling\n'
                  '• Perceptual Hashing (pHash + dHash)\n'
                  '• Android MediaStore API via photo_manager\n'
                  '• MVVM architecture with clean separation of concerns',
            ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 12),

            // ── Features ─────────────────────────────────────────────────
            _InfoCard(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              title: 'Key Features',
              body: '• AI quality scoring: sharpness, blur, exposure, noise\n'
                  '• Face analysis: eyes, smile, pose, photobombers\n'
                  '• Duplicate detection: exact + perceptual similarity\n'
                  '• Burst, WhatsApp, screenshot, and download detection\n'
                  '• Dark mode & Light mode\n'
                  '• Pause/resume scanning\n'
                  '• Never deletes automatically — always confirms first',
            ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            Text(
              '© 2024 Smart Photo Cleaner\nAll rights reserved.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ).animate(delay: 700.ms).fade(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   body;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.6)),
          ],
        ),
      ),
    );
  }
}
