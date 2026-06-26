import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../data/services/scanner_service.dart';
import '../providers/scanner_provider.dart';
import '../widgets/scan_progress_widget.dart';

/// Full-screen scanner view with real-time progress, pause, and resume.
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs       = Theme.of(context).colorScheme;
    final tt       = Theme.of(context).textTheme;
    final progress = ref.watch(scanProgressProvider).valueOrNull ??
        const ScanProgress(status: ScanStatus.idle);
    final notifier = ref.read(photoGroupsProvider.notifier);

    final isDone    = progress.status == ScanStatus.done;
    final isError   = progress.status == ScanStatus.error;
    final isPaused  = progress.status == ScanStatus.paused;
    final isRunning = !isDone && !isError && progress.status != ScanStatus.idle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning…'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isRunning)
            TextButton.icon(
              onPressed: notifier.cancelScan,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Cancel'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Animated scanning illustration ─────────────────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ScanAnimation(status: progress.status),
                    const SizedBox(height: 32),
                    Text(
                      progress.statusLabel,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ).animate(key: ValueKey(progress.statusLabel))
                        .fade(duration: 300.ms),
                    const SizedBox(height: 8),
                    if (progress.currentPhotoName.isNotEmpty)
                      Text(
                        progress.currentPhotoName,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).animate().fade(duration: 200.ms),
                  ],
                ),
              ),
            ),

            // ── Progress details ───────────────────────────────────────────
            ScanProgressWidget(progress: progress),
            const SizedBox(height: 24),

            // ── Pause / Resume / Done ──────────────────────────────────────
            if (isDone) ...[
              _ResultsSummary(progress: progress),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  'View Results — ${progress.groupsFound} groups found',
                ),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            ] else if (isError) ...[
              Card(
                color: cs.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: cs.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          progress.errorMessage ?? 'An error occurred.',
                          style: TextStyle(color: cs.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  notifier.startScan();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Scan'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isPaused ? notifier.resumeScan : notifier.pauseScan,
                      icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                      label: Text(isPaused ? 'Resume' : 'Pause'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Scanning animation ────────────────────────────────────────────────────────

class _ScanAnimation extends StatelessWidget {
  final ScanStatus status;
  const _ScanAnimation({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone  = status == ScanStatus.done;
    final isError = status == ScanStatus.error;

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: isError
            ? cs.errorContainer
            : isDone
                ? cs.primaryContainer.withOpacity(0.3)
                : cs.primaryContainer.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isDone && !isError)
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cs.primary.withOpacity(0.3),
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
          Icon(
            isError
                ? Icons.error_outline_rounded
                : isDone
                    ? Icons.check_circle_rounded
                    : Icons.auto_awesome_rounded,
            size: 64,
            color: isError ? cs.error : cs.primary,
          )
              .animate(key: ValueKey(status))
              .scale(duration: 400.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }
}

// ── Results summary ───────────────────────────────────────────────────────────

class _ResultsSummary extends StatelessWidget {
  final ScanProgress progress;
  const _ResultsSummary({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Metric(icon: Icons.photo_library_rounded,
                label: 'Photos', value: '${progress.photosAnalyzed}'),
            _Metric(icon: Icons.folder_special_rounded,
                label: 'Groups', value: '${progress.groupsFound}'),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: cs.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700, color: cs.primary)),
        Text(label, style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}
