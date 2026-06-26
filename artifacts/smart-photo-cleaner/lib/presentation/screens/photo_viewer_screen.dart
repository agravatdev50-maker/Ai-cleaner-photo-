import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../data/models/photo_model.dart';
import '../../data/models/photo_group_model.dart';
import '../providers/scanner_provider.dart';
import '../widgets/best_photo_badge.dart';

/// Full-screen photo viewer with pinch-to-zoom and swipe navigation.
/// Shows quality scores, deletion reasons, and selection toggle.
class PhotoViewerScreen extends ConsumerStatefulWidget {
  final String groupId;
  final int    initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.groupId,
    required this.initialIndex,
  });

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  PhotoGroupModel? get _group {
    final groups = ref.read(photoGroupsProvider);
    try {
      return groups.firstWhere((g) => g.id == widget.groupId);
    } catch (_) {
      return null;
    }
  }

  List<PhotoModel> get _photos => _group?.photos ?? [];
  PhotoModel?      get _current => _photos.isEmpty ? null : _photos[_currentIndex.clamp(0, _photos.length - 1)];

  @override
  Widget build(BuildContext context) {
    ref.watch(photoGroupsProvider); // rebuild on selection changes
    final cs     = Theme.of(context).colorScheme;
    final photos = _photos;
    final current = _current;
    if (photos.isEmpty || current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Photo Viewer')),
        body: const Center(child: Text('Photo not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Photo gallery (swipeable) ──────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _showInfo = !_showInfo),
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              builder: (ctx, i) => PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(photos[i].path)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: photos[i].id),
              ),
              loadingBuilder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),

          // ── Top bar ────────────────────────────────────────────────────
          AnimatedOpacity(
            opacity: _showInfo ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _TopBar(
              current:  current,
              index:    _currentIndex,
              total:    photos.length,
              onClose:  () => Navigator.pop(context),
              onToggle: () => ref.read(photoGroupsProvider.notifier)
                  .toggleSelection(_group!.id, current.id),
            ),
          ),

          // ── Bottom info panel ──────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            bottom: _showInfo ? 0 : -300,
            left: 0,
            right: 0,
            child: _InfoPanel(photo: current),
          ),

          // ── Best Photo badge ───────────────────────────────────────────
          if (current.isBestInGroup)
            const Positioned(
              top: 90,
              left: 16,
              child: BestPhotoBadge(),
            ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final PhotoModel current;
  final int index;
  final int total;
  final VoidCallback onClose;
  final VoidCallback onToggle;

  const _TopBar({
    required this.current,
    required this.index,
    required this.total,
    required this.onClose,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: onClose,
              ),
              const Spacer(),
              Text(
                '${index + 1} / $total',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Selection checkbox
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: current.isSelected ? Colors.red : Colors.transparent,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: current.isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info panel ────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  final PhotoModel photo;
  const _InfoPanel({required this.photo});

  @override
  Widget build(BuildContext context) {
    final q  = photo.quality;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // File name
          Text(
            photo.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Metadata row
          Row(
            children: [
              _MetaChip(Icons.photo_size_select_actual_rounded, photo.resolution),
              const SizedBox(width: 8),
              _MetaChip(Icons.storage_rounded, photo.formattedSize),
              const SizedBox(width: 8),
              _MetaChip(Icons.calendar_today_rounded,
                  _formatDate(photo.dateCreated)),
            ],
          ),

          // Deletion reasons
          if (photo.deletionReasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: photo.deletionReasons.take(4).map((r) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(r.icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(r.label,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              )).toList(),
            ),
          ],

          // Quality bar
          const SizedBox(height: 12),
          if (q.analysisComplete) _QualityBar(quality: q),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _QualityBar extends StatelessWidget {
  final QualityAnalysis quality;
  const _QualityBar({required this.quality});

  @override
  Widget build(BuildContext context) {
    final score = quality.overallScore;
    final color = score > 0.7 ? Colors.green : score > 0.4 ? Colors.orange : Colors.red;

    return Row(
      children: [
        const Text('Quality', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              color: color,
              backgroundColor: Colors.white24,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(score * 100).toInt()}%',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
