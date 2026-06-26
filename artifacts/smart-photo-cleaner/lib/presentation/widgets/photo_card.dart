import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/photo_model.dart';
import '../../core/utils/format_utils.dart';
import 'best_photo_badge.dart';

/// A standalone photo card used in list views — shows thumbnail, 
/// quality score, and deletion reasons.
class PhotoCard extends StatelessWidget {
  final PhotoModel    photo;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSelect;

  const PhotoCard({
    super.key,
    required this.photo,
    this.onTap,
    this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // ── Thumbnail ─────────────────────────────────────────────────
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(photo.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_rounded),
                    ),
                  ),
                  if (photo.isBestInGroup)
                    const Positioned(
                      top: 4,
                      left: 4,
                      child: BestPhotoBadge(compact: true),
                    ),
                  if (photo.isSelected)
                    Container(color: cs.primary.withOpacity(0.3)),
                ],
              ),
            ),

            // ── Info ──────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.name,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${photo.resolution} • ${photo.formattedSize} • '
                      '${FormatUtils.formatDate(photo.dateCreated)}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (photo.deletionReasons.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: photo.deletionReasons.take(2).map((r) =>
                            _ReasonChip(reason: r)).toList(),
                      ),
                    ],
                    if (photo.quality.analysisComplete) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('Quality:', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: photo.quality.overallScore,
                                minHeight: 4,
                                color: _qualityColor(photo.quality.overallScore),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            FormatUtils.formatScore(photo.quality.overallScore),
                            style: TextStyle(
                              fontSize: 11,
                              color: _qualityColor(photo.quality.overallScore),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Checkbox ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: onToggleSelect,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: photo.isSelected ? cs.primary : Colors.transparent,
                    border: Border.all(
                      color: photo.isSelected ? cs.primary : cs.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: photo.isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : null,
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

class _ReasonChip extends StatelessWidget {
  final DeletionReason reason;
  const _ReasonChip({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(
        '${reason.icon} ${reason.label}',
        style: const TextStyle(fontSize: 10, color: Colors.red),
      ),
    );
  }
}
