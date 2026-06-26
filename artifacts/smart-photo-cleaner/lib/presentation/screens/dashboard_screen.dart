import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/photo_group_model.dart';
import '../../data/services/scanner_service.dart';
import '../providers/scanner_provider.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/scan_progress_widget.dart';

/// Main dashboard — shows stats, scan controls, and category navigation.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final scanAsync = ref.watch(scanProgressProvider);
    final stats     = ref.watch(scanStatsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _DashboardTab(scanAsync: scanAsync, stats: stats),
          const _SearchTab(),
          const _SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  final AsyncValue<ScanProgress> scanAsync;
  final ScanStats stats;

  const _DashboardTab({required this.scanAsync, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final progress = scanAsync.valueOrNull;
    final isScanning = progress != null &&
        progress.status != ScanStatus.idle &&
        progress.status != ScanStatus.done &&
        progress.status != ScanStatus.error;

    return CustomScrollView(
      slivers: [
        // ── AppBar ─────────────────────────────────────────────────────────
        SliverAppBar.large(
          floating: true,
          title: const Text('Smart Photo Cleaner'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => context.push(AppRoutes.help),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => context.push(AppRoutes.about),
            ),
          ],
        ),

        // ── Scan progress ──────────────────────────────────────────────────
        if (isScanning)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ScanProgressWidget(progress: progress!),
            ).animate().slideY(begin: -0.2, end: 0, duration: 400.ms).fade(),
          ),

        // ── Scan button ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _ScanButton(isScanning: isScanning, progress: progress),
          ),
        ),

        // ── Storage summary ────────────────────────────────────────────────
        if (stats.totalPhotos > 0)
          SliverToBoxAdapter(
            child: _StorageSummary(stats: stats),
          ),

        // ── Section header ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              'Categories',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),

        // ── Stat cards grid ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              DashboardStatCard(
                icon: Icons.copy_all_rounded,
                label: 'Duplicates',
                count: stats.duplicatePhotos,
                iconColor: Colors.red,
                onTap: () => context.push(
                  '${AppRoutes.photoGroups}?category=${AppConstants.categoryDuplicates}&title=Duplicate Photos',
                ),
              ).animate(delay: 50.ms).slideY(begin: 0.2, end: 0, duration: 400.ms).fade(),

              DashboardStatCard(
                icon: Icons.photo_library_rounded,
                label: 'Similar',
                count: stats.similarPhotos,
                iconColor: Colors.orange,
                onTap: () => context.push(
                  '${AppRoutes.photoGroups}?category=${AppConstants.categorySimilar}&title=Similar Photos',
                ),
              ).animate(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms).fade(),

              DashboardStatCard(
                icon: Icons.screenshot_monitor_rounded,
                label: 'Screenshots',
                count: stats.screenshotPhotos,
                iconColor: Colors.blue,
                onTap: () => context.push(
                  '${AppRoutes.photoGroups}?category=${AppConstants.categoryScreenshots}&title=Screenshots',
                ),
              ).animate(delay: 150.ms).slideY(begin: 0.2, end: 0, duration: 400.ms).fade(),

              DashboardStatCard(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                count: stats.whatsAppPhotos,
                iconColor: const Color(0xFF25D366),
                onTap: () => context.push(
                  '${AppRoutes.photoGroups}?category=${AppConstants.categoryWhatsApp}&title=WhatsApp Images',
                ),
              ).animate(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms).fade(),

              DashboardStatCard(
                icon: Icons.download_rounded,
                label: 'Downloads',
                count: stats.downloadPhotos,
                iconColor: Colors.purple,
                onTap: () => context.push(
                  '${AppRoutes.photoGroups}?category=${AppConstants.categoryDownloads}&title=Downloads',
                ),
              ).animate(delay: 250.ms).slideY(begin: 0.2, end: 0, duration: 400.ms).fade(),

              DashboardStatCard(
                icon: Icons.burst_mode_rounded,
                label: 'Burst Photos',
                count: stats.burstPhotos,
                iconColor: Colors.amber,
                onTap: () => context.push(
                  '${AppRoutes.photoGroups}?category=${AppConstants.categoryBurst}&title=Burst Photos',
                ),
              ).animate(delay: 300.ms).slideY(begin: 0.2, end: 0, duration: 400.ms).fade(),
            ],
          ),
        ),

        // ── All groups CTA ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                '${AppRoutes.photoGroups}?category=all&title=All Groups',
              ),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('View All Groups'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── Scan button ───────────────────────────────────────────────────────────────

class _ScanButton extends ConsumerWidget {
  final bool isScanning;
  final ScanProgress? progress;

  const _ScanButton({required this.isScanning, required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(photoGroupsProvider.notifier);
    final isPaused = progress?.status == ScanStatus.paused;

    if (!isScanning) {
      return FilledButton.icon(
        onPressed: () {
          notifier.startScan();
          context.push(AppRoutes.scanner);
        },
        icon: const Icon(Icons.search_rounded),
        label: const Text('Scan My Photos'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.scanner),
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('View Progress'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: isPaused ? notifier.resumeScan : notifier.pauseScan,
          icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
          style: IconButton.styleFrom(
            minimumSize: const Size(52, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

// ── Storage summary ───────────────────────────────────────────────────────────

class _StorageSummary extends StatelessWidget {
  final ScanStats stats;
  const _StorageSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Storage', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    '${stats.totalPhotos} photos',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StorageMetric(
                      label: 'Total Used',
                      value: stats.formattedTotalStorage,
                      color: cs.primary,
                    ),
                  ),
                  Expanded(
                    child: _StorageMetric(
                      label: 'Can Be Freed',
                      value: stats.formattedReclaimable,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Storage usage bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stats.totalStorageBytes == 0
                      ? 0
                      : stats.reclaimableBytes / stats.totalStorageBytes,
                  minHeight: 8,
                  color: Colors.green,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a category below to review and delete photos',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StorageMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StorageMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: tt.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
        Text(label, style: tt.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ── Search tab ────────────────────────────────────────────────────────────────

class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab();
  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          floating: true,
          title: const Text('Search'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchBar(
                controller: _ctrl,
                hintText: 'Search albums, filenames…',
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_ctrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _ctrl.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    ),
                ],
                onChanged: (q) =>
                    ref.read(searchQueryProvider.notifier).state = q,
              ),
            ),
          ),
        ),
        if (results.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No results', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final group = results[i];
              // Navigate to the photo groups screen filtered to the group's
              // category so the query-param contract is respected.
              return ListTile(
                leading: Icon(Icons.photo_library_rounded, color: cs.primary),
                title: Text(group.photos.first.name),
                subtitle: Text('${group.photos.length} photos • ${group.categoryLabel}'),
                onTap: () => context.push(
                  '${AppRoutes.photoGroups}'
                  '?category=${group.category.name}'
                  '&title=${Uri.encodeComponent(group.categoryLabel)}',
                ),
              );
            },
          ),
      ],
    );
  }
}

// ── Settings tab (shortcut) ───────────────────────────────────────────────────

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Navigate to the real settings screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.push(AppRoutes.settings);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
