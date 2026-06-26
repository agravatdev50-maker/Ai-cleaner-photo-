import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/photo_group_model.dart';
import '../../data/repositories/photo_repository.dart';
import '../../data/services/scanner_service.dart';

// ── Repository singleton ───────────────────────────────────────────────────

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  final repo = PhotoRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

// ── Scan progress ──────────────────────────────────────────────────────────

final scanProgressProvider = StreamProvider<ScanProgress>((ref) {
  return ref.watch(photoRepositoryProvider).progressStream;
});

// ── Photo groups ───────────────────────────────────────────────────────────

class PhotoGroupsNotifier extends Notifier<List<PhotoGroupModel>> {
  late final PhotoRepository _repo;
  StreamSubscription? _sub;

  @override
  List<PhotoGroupModel> build() {
    _repo = ref.watch(photoRepositoryProvider);

    // Subscribe to scanner group updates
    _sub = _repo.groupStream.listen((groups) {
      _repo.updateGroups(groups);
      state = _repo.groups;
    });
    ref.onDispose(() => _sub?.cancel());

    return [];
  }

  /// Start a fresh scan.
  Future<void> startScan() async {
    state = [];
    await _repo.startScan();
  }

  void pauseScan()  => _repo.pauseScan();
  void resumeScan() => _repo.resumeScan();
  void cancelScan() => _repo.cancelScan();

  // ── Selection ────────────────────────────────────────────────────────────

  void toggleSelection(String groupId, String photoId) {
    _repo.togglePhotoSelection(groupId, photoId);
    state = [..._repo.groups];
  }

  void selectAllSuggested() {
    _repo.selectAllSuggested();
    state = [..._repo.groups];
  }

  void deselectAll() {
    _repo.deselectAll();
    state = [..._repo.groups];
  }

  // ── Deletion ─────────────────────────────────────────────────────────────

  Future<DeleteResult> deleteSelected() async {
    final result = await _repo.deleteSelected();
    state = [..._repo.groups];
    return result;
  }

  // ── Derived getters ───────────────────────────────────────────────────────

  List<PhotoGroupModel> groupsForCategory(String category) =>
      _repo.groupsForCategory(category);

  List<PhotoGroupModel> searchGroups(String query) =>
      _repo.searchGroups(query);

  ScanStats get stats => _repo.stats;

  int get selectedCount => _repo.selectedPhotos.length;
  int get selectedBytes => _repo.selectedBytes;
}

final photoGroupsProvider =
    NotifierProvider<PhotoGroupsNotifier, List<PhotoGroupModel>>(
        PhotoGroupsNotifier.new);

// ── Filtered groups (per category) ────────────────────────────────────────

final filteredGroupsProvider =
    Provider.family<List<PhotoGroupModel>, String>((ref, category) {
  final notifier = ref.watch(photoGroupsProvider.notifier);
  ref.watch(photoGroupsProvider); // rebuild when state changes
  return notifier.groupsForCategory(category);
});

// ── Search results ────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<PhotoGroupModel>>((ref) {
  final query   = ref.watch(searchQueryProvider);
  final notifier = ref.watch(photoGroupsProvider.notifier);
  ref.watch(photoGroupsProvider);
  return notifier.searchGroups(query);
});

// ── Stats ─────────────────────────────────────────────────────────────────

final scanStatsProvider = Provider<ScanStats>((ref) {
  ref.watch(photoGroupsProvider); // rebuild when groups change
  return ref.watch(photoGroupsProvider.notifier).stats;
});

// ── Selection summary ─────────────────────────────────────────────────────

final selectionSummaryProvider = Provider<({int count, int bytes})>((ref) {
  ref.watch(photoGroupsProvider);
  final notifier = ref.watch(photoGroupsProvider.notifier);
  return (count: notifier.selectedCount, bytes: notifier.selectedBytes);
});
