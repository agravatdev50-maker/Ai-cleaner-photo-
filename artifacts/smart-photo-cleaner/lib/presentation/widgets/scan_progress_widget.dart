import 'package:flutter/material.dart';
import '../../data/services/scanner_service.dart';

/// Compact progress card shown during scanning.
/// Displays step label, progress bars for loading and analysis, and counts.
class ScanProgressWidget extends StatelessWidget {
  final ScanProgress progress;
  const ScanProgressWidget({super.key, required this.progress});

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
            // ── Status label ─────────────────────────────────────────────
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: progress.status == ScanStatus.done
                      ? Icon(Icons.check_circle_rounded, size: 16, color: Colors.green)
                      : progress.status == ScanStatus.paused
                          ? Icon(Icons.pause_circle_rounded, size: 16, color: Colors.orange)
                          : CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progress.statusLabel,
                    style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (progress.groupsFound > 0)
                  Text(
                    '${progress.groupsFound} groups',
                    style: tt.labelSmall?.copyWith(color: cs.primary),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Loading progress ─────────────────────────────────────────
            if (progress.totalPhotos > 0) ...[
              _ProgressRow(
                label: 'Loading',
                value: progress.loadProgress,
                current: progress.photosLoaded,
                total:   progress.totalPhotos,
              ),
              const SizedBox(height: 8),
            ],

            // ── Analysis progress ─────────────────────────────────────────
            if (progress.photosAnalyzed > 0 || progress.status == ScanStatus.analyzingQuality) ...[
              _ProgressRow(
                label: 'Analyzing',
                value: progress.analysisProgress,
                current: progress.photosAnalyzed,
                total:   progress.totalPhotos,
                color: Colors.teal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final int    current;
  final int    total;
  final Color? color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.current,
    required this.total,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            Text('$current / $total',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            color: color ?? cs.primary,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
