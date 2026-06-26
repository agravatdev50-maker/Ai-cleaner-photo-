import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../data/models/photo_group_model.dart';
import '../../data/models/photo_model.dart';
import '../providers/scanner_provider.dart';
import '../widgets/group_card.dart';
import 'delete_review_screen.dart';

/// Shows all photo groups for a given category.
/// Supports sorting, selection, and bulk deletion.
class PhotoGroupsScreen extends ConsumerStatefulWidget {
  final String category;
  final String title;

  const PhotoGroupsScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  ConsumerState<PhotoGroupsScreen> createState() => _PhotoGroupsScreenState();
}

class _PhotoGroupsScreenState extends ConsumerState<PhotoGroupsScreen> {
  _SortOption _sort = _SortOption.date;
  bool _showOnlySuggested = false;

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final groups  = ref.watch(filteredGroupsProvider(widget.category));
    final summary = ref.watch(selectionSummaryProvider);

    final sorted = _sortGroups(groups);

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar.large(
            floating: true,
            title: Text(widget.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.sort_rounded),
                onPressed: () => _showSortSheet(context),
                tooltip: 'Sort',
              ),
              IconButton(
                icon: Icon(_showOnlySuggested
                    ? Icons.filter_list_off_rounded
                    : Icons.filter_list_rounded),
                onPressed: () =>
                    setState(() => _showOnlySuggested = !_showOnlySuggested),
                tooltip: 'Filter suggested',
              ),
            ],
          ),

          // ── Bulk action bar ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _BulkActionBar(summary: summary),
          ),

          // ── Groups ────────────────────────────────────────────────────────
          if (sorted.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(category: widget.category),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.builder(
                itemCount: sorted.length,
                itemBuilder: (ctx, i) {
                  final group = sorted[i];
                  return GroupCard(
                    group: group,
                    onPhotoTap: (photo) => _openViewer(context, group, photo),
                    onToggleSelect: (photo) {
                      ref.read(photoGroupsProvider.notifier)
                          .toggleSelection(group.id, photo.id);
                    },
                    showOnlySuggested: _showOnlySuggested,
                  ).animate(delay: Duration(milliseconds: i * 40))
                      .slideY(begin: 0.1, end: 0, duration: 300.ms)
                      .fade(duration: 300.ms);
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── FAB — Delete selected ─────────────────────────────────────────────
      floatingActionButton: summary.count > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.deleteReview),
              icon: const Icon(Icons.delete_sweep_rounded),
              label: Text('Review ${summary.count} photos'),
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
            ).animate().scale(duration: 300.ms, curve: Curves.elasticOut)
          : null,
    );
  }

  List<PhotoGroupModel> _sortGroups(List<PhotoGroupModel> groups) {
    final copy = [...groups];
    switch (_sort) {
      case _SortOption.date:
        copy.sort((a, b) {
          final aDate = a.photos.first.dateCreated;
          final bDate = b.photos.first.dateCreated;
          return bDate.compareTo(aDate);
        });
        break;
      case _SortOption.size:
        copy.sort((a, b) => b.totalSizeBytes.compareTo(a.totalSizeBytes));
        break;
      case _SortOption.quality:
        copy.sort((a, b) {
          final aQ = a.photos.fold(0.0, (s, p) => s + p.quality.overallScore) / a.photos.length;
          final bQ = b.photos.fold(0.0, (s, p) => s + p.quality.overallScore) / b.photos.length;
          return bQ.compareTo(aQ);
        });
        break;
      case _SortOption.count:
        copy.sort((a, b) => b.photos.length.compareTo(a.photos.length));
        break;
    }
    return copy;
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _SortSheet(
        current: _sort,
        onSelected: (s) {
          setState(() => _sort = s);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openViewer(BuildContext context, PhotoGroupModel group, PhotoModel photo) {
    final idx = group.photos.indexOf(photo);
    context.push(AppRoutes.photoViewer, extra: {
      'groupId':      group.id,
      'initialIndex': idx < 0 ? 0 : idx,
    });
  }
}

// ── Bulk action bar ───────────────────────────────────────────────────────────

class _BulkActionBar extends ConsumerWidget {
  final ({int count, int bytes}) summary;
  const _BulkActionBar({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final notifier = ref.read(photoGroupsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: notifier.selectAllSuggested,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Select All Suggested'),
            ),
          ),
          if (summary.count > 0) ...[
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: notifier.deselectAll,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Deselect All'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sort bottom sheet ─────────────────────────────────────────────────────────

enum _SortOption { date, size, quality, count }

class _SortSheet extends StatelessWidget {
  final _SortOption current;
  final void Function(_SortOption) onSelected;

  const _SortSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      (option: _SortOption.date,    label: 'Date (newest first)',     icon: Icons.calendar_today_rounded),
      (option: _SortOption.size,    label: 'Size (largest first)',    icon: Icons.data_usage_rounded),
      (option: _SortOption.quality, label: 'Quality (best first)',    icon: Icons.star_rounded),
      (option: _SortOption.count,   label: 'Group size (most first)', icon: Icons.photo_library_rounded),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
          const Divider(height: 24),
          ...options.map((o) => ListTile(
                leading: Icon(o.icon),
                title: Text(o.label),
                trailing: o.option == current
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => onSelected(o.option),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String category;
  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'All clear!',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'No photos found in this category.\nRun a scan to analyze your gallery.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
