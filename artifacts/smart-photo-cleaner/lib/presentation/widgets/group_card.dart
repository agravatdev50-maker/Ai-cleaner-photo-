import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/photo_group_model.dart';
import '../../data/models/photo_model.dart';
import 'best_photo_badge.dart';

/// Displays a single photo group (duplicate/similar/etc.) with all photos
/// in a horizontal scroll row, selection checkboxes, and deletion reason tags.
class GroupCard extends StatelessWidget {
  final PhotoGroupModel group;
  final void Function(PhotoModel)  onPhotoTap;
  final void Function(PhotoModel)  onToggleSelect;
  final bool                       showOnlySuggested;

  const GroupCard({
    super.key,
    required this.group,
    required this.onPhotoTap,
    required this.onToggleSelect,
    this.showOnlySuggested = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final tt   = Theme.of(context).textTheme;
    final photos = showOnlySuggested
        ? group.photos.where((p) => p.isSuggestedForDeletion).toList()
        : group.photos;

    if (photos.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${group.categoryIcon}  ${group.categoryLabel}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.photos.length} photos',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                // Reclaimable size
                Text(
                  group.reclaimableSizeBytes > 0
                      ? '💾 ${_fmt(group.reclaimableSizeBytes)}'
                      : '',
                  style: tt.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── Photo strip ─────────────────────────────────────────────────
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) => _PhotoTile(
                photo: photos[i],
                onTap:    () => onPhotoTap(photos[i]),
                onToggle: () => onToggleSelect(photos[i]),
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static String _fmt(int bytes) {
    if (bytes < 1048576)    return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }
}

// ── Individual photo tile ─────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _PhotoTile({required this.photo, required this.onTap, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photo ─────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photo.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_rounded),
                ),
              ),
            ),

            // ── Selection overlay ─────────────────────────────────────────
            if (photo.isSelected)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(color: cs.primary.withOpacity(0.4)),
              ),

            // ── Suggested-for-deletion tint ───────────────────────────────
            if (photo.isSuggestedForDeletion && !photo.isBestInGroup)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(color: Colors.red.withOpacity(0.15)),
              ),

            // ── Best photo badge ──────────────────────────────────────────
            if (photo.isBestInGroup)
              const Positioned(
                top: 6,
                left: 6,
                child: BestPhotoBadge(compact: true),
              ),

            // ── Checkbox ──────────────────────────────────────────────────
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: photo.isSelected ? cs.primary : Colors.black38,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: photo.isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
              ),
            ),

            // ── Bottom info strip ─────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quality score bar
                      if (photo.quality.analysisComplete)
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: photo.quality.overallScore,
                                  minHeight: 3,
                                  color: _qualityColor(photo.quality.overallScore),
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 3),
                      // Top deletion reason
                      if (photo.deletionReasons.isNotEmpty)
                        Text(
                          '${photo.deletionReasons.first.icon} ${photo.deletionReasons.first.label}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _qualityColor(double score) {
    if (score > 0.7) return Colors.green;
    if (score > 0.4) return Colors.orange;
    return Colors.red;
  }
}
