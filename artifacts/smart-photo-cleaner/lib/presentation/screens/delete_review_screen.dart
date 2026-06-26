import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/photo_model.dart';
import '../../data/repositories/photo_repository.dart';
import '../providers/scanner_provider.dart';

/// Review screen shown before deletion.
/// Displays selected photo thumbnails, count, and total storage to be freed.
/// Deletion NEVER happens automatically — user must confirm here.
class DeleteReviewScreen extends ConsumerStatefulWidget {
  const DeleteReviewScreen({super.key});

  @override
  ConsumerState<DeleteReviewScreen> createState() => _DeleteReviewScreenState();
}

class _DeleteReviewScreenState extends ConsumerState<DeleteReviewScreen> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final summary = ref.watch(selectionSummaryProvider);
    final groups  = ref.watch(photoGroupsProvider);
    final selected = groups
        .expand((g) => g.photos)
        .where((p) => p.isSelected)
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Review Deletion'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Summary banner ───────────────────────────────────────────────
          _SummaryBanner(summary: summary),

          // ── Warning note ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              color: cs.errorContainer.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: cs.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Deleted photos are moved to the Trash and can be '
                        'restored from your gallery within 30 days.',
                        style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Photo grid ───────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: selected.length,
              itemBuilder: (ctx, i) => _PhotoThumb(
                photo: selected[i],
                onDeselect: () {
                  ref.read(photoGroupsProvider.notifier)
                      .toggleSelection(selected[i].groupId!, selected[i].id);
                },
              ).animate(delay: Duration(milliseconds: i * 30))
                  .scale(duration: 200.ms, begin: const Offset(0.8, 0.8))
                  .fade(duration: 200.ms),
            ),
          ),

          // ── Action buttons ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FilledButton.icon(
                    onPressed: _deleting ? null : () => _confirmAndDelete(context),
                    icon: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.delete_sweep_rounded),
                    label: Text(
                      _deleting
                          ? 'Deleting…'
                          : 'Delete ${summary.count} Photos',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final summary = ref.read(selectionSummaryProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        count: summary.count,
        bytes: summary.bytes,
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      final result = await ref.read(photoGroupsProvider.notifier).deleteSelected();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.hasFailures
                ? 'Deleted ${result.deletedCount} photos. ${result.failedIds.length} failed.'
                : 'Deleted ${result.deletedCount} photos • freed ${result.formattedFreedBytes}',
          ),
          backgroundColor: result.hasFailures ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

// ── Summary banner ────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final ({int count, int bytes}) summary;
  const _SummaryBanner({required this.summary});

  String _formatBytes(int bytes) {
    if (bytes < 1048576)    return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${summary.count}',
                    style: tt.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800, color: cs.error)),
                Text('Photos selected', style: tt.bodyMedium?.copyWith(color: cs.onErrorContainer)),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: cs.error.withOpacity(0.3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatBytes(summary.bytes),
                    style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, color: Colors.green)),
                Text('Will be freed', style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo thumbnail with deselect ─────────────────────────────────────────────

class _PhotoThumb extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback onDeselect;

  const _PhotoThumb({required this.photo, required this.onDeselect});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(photo.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image_rounded),
            ),
          ),
        ),
        // Deselect X button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDeselect,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
        // Deletion reason label
        if (photo.deletionReasons.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
              ),
              child: Text(
                '${photo.deletionReasons.first.icon} ${photo.deletionReasons.first.label}',
                style: const TextStyle(color: Colors.white, fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Confirmation dialog ───────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final int count;
  final int bytes;

  const _ConfirmDialog({required this.count, required this.bytes});

  String get _formattedBytes {
    if (bytes < 1048576)    return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.delete_forever_rounded, color: cs.error, size: 40),
      title: const Text('Confirm Deletion'),
      content: Text(
        'You are about to delete $count photos and free $_formattedBytes of storage.\n\n'
        'Photos will be moved to Trash and can be restored from your gallery.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
