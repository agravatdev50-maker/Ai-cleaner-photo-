import 'dart:async';
import '../models/photo_model.dart';
import '../models/photo_group_model.dart';
import '../services/media_store_service.dart';
import '../services/scanner_service.dart';
import '../../core/constants/app_constants.dart';

/// Repository layer — single source of truth for all photo data in the app.
/// Sits between Riverpod providers and the raw data services.
class PhotoRepository {
  final MediaStoreService _mediaStore = MediaStoreService();
  final ScannerService    _scanner    = ScannerService();

  // ── State ─────────────────────────────────────────────────────────────────
  List<PhotoGroupModel> _groups  = [];
  ScanStats             _stats   = const ScanStats();

  List<PhotoGroupModel> get groups  => List.unmodifiable(_groups);
  ScanStats             get stats   => _stats;
  ScannerService        get scanner => _scanner;

  // ── Scanning ──────────────────────────────────────────────────────────────

  Stream<ScanProgress>        get progressStream => _scanner.progressStream;
  Stream<List<PhotoGroupModel>> get groupStream  => _scanner.groupStream;

  /// Start a fresh scan. Groups are emitted via [groupStream].
  Future<void> startScan() async {
    _groups = [];
    await _scanner.startScan();
  }

  void pauseScan()  => _scanner.pause();
  void resumeScan() => _scanner.resume();
  void cancelScan() => _scanner.cancel();

  /// Called when the scanner emits new groups — replaces in-memory state.
  void updateGroups(List<PhotoGroupModel> groups) {
    _groups = groups;
    _stats  = _buildStats(groups);
  }

  // ── Selection management ──────────────────────────────────────────────────

  /// Toggle selection state of a single photo.
  void togglePhotoSelection(String groupId, String photoId) {
    _groups = _groups.map((g) {
      if (g.id != groupId) return g;
      final photos = g.photos.map((p) {
        if (p.id != photoId) return p;
        return p.copyWith(isSelected: !p.isSelected);
      }).toList();
      return g.copyWith(photos: photos);
    }).toList();
  }

  /// Select all suggested-for-deletion photos across all groups.
  void selectAllSuggested() {
    _groups = _groups.map((g) {
      final photos = g.photos.map((p) {
        return p.copyWith(isSelected: p.isSuggestedForDeletion ? true : p.isSelected);
      }).toList();
      return g.copyWith(photos: photos);
    }).toList();
  }

  /// Deselect all photos.
  void deselectAll() {
    _groups = _groups.map((g) {
      final photos = g.photos.map((p) => p.copyWith(isSelected: false)).toList();
      return g.copyWith(photos: photos);
    }).toList();
  }

  /// All photos currently selected for deletion across all groups.
  List<PhotoModel> get selectedPhotos =>
      _groups.expand((g) => g.photos).where((p) => p.isSelected).toList();

  /// Total bytes of selected photos.
  int get selectedBytes =>
      selectedPhotos.fold(0, (sum, p) => sum + p.sizeBytes);

  // ── Deletion ──────────────────────────────────────────────────────────────

  /// Delete all selected photos from the device.
  /// Never deletes automatically — caller must have confirmed with the user.
  Future<DeleteResult> deleteSelected() async {
    final toDelete = selectedPhotos;
    if (toDelete.isEmpty) return const DeleteResult(deletedCount: 0, freedBytes: 0);

    final freedBytes = selectedBytes;
    final deletedIds = await _mediaStore.deletePhotos(toDelete);

    // Remove successfully deleted photos from groups
    _groups = _groups.map((g) {
      final remaining = g.photos.where((p) => !deletedIds.contains(p.id)).toList();
      return g.copyWith(photos: remaining);
    }).where((g) => g.photos.length >= 2 ||
        (g.photos.length == 1 && g.category == PhotoCategory.screenshot)).toList();

    _stats = _buildStats(_groups);

    return DeleteResult(
      deletedCount: deletedIds.length,
      freedBytes:   freedBytes,
      failedIds:    toDelete.map((p) => p.id).where((id) => !deletedIds.contains(id)).toList(),
    );
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  /// Filter groups by category.
  List<PhotoGroupModel> groupsForCategory(String category) {
    switch (category) {
      case AppConstants.categoryDuplicates:
        return _groups.where((g) => g.category == PhotoCategory.duplicate).toList();
      case AppConstants.categorySimilar:
        return _groups.where((g) => g.category == PhotoCategory.similar ||
            g.category == PhotoCategory.burst ||
            g.category == PhotoCategory.edited ||
            g.category == PhotoCategory.resized).toList();
      case AppConstants.categoryScreenshots:
        return _groups.where((g) => g.category == PhotoCategory.screenshot).toList();
      case AppConstants.categoryWhatsApp:
        return _groups.where((g) => g.category == PhotoCategory.whatsApp).toList();
      case AppConstants.categoryDownloads:
        return _groups.where((g) => g.category == PhotoCategory.download).toList();
      case AppConstants.categoryBurst:
        return _groups.where((g) => g.category == PhotoCategory.burst).toList();
      default:
        return _groups;
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  List<PhotoGroupModel> searchGroups(String query) {
    if (query.trim().isEmpty) return _groups;
    final q = query.toLowerCase();
    return _groups.where((g) =>
        g.photos.any((p) =>
            p.name.toLowerCase().contains(q) ||
            p.bucketName.toLowerCase().contains(q))).toList();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  ScanStats _buildStats(List<PhotoGroupModel> groups) {
    final allPhotos    = groups.expand((g) => g.photos).toList();
    final reclaimable  = allPhotos.where((p) => p.isSuggestedForDeletion);

    return ScanStats(
      totalPhotos:       allPhotos.length,
      duplicatePhotos:   groups.where((g) => g.category == PhotoCategory.duplicate).expand((g) => g.photos).length,
      similarPhotos:     groups.where((g) => g.category == PhotoCategory.similar || g.category == PhotoCategory.burst).expand((g) => g.photos).length,
      screenshotPhotos:  groups.where((g) => g.category == PhotoCategory.screenshot).expand((g) => g.photos).length,
      whatsAppPhotos:    groups.where((g) => g.category == PhotoCategory.whatsApp).expand((g) => g.photos).length,
      downloadPhotos:    groups.where((g) => g.category == PhotoCategory.download).expand((g) => g.photos).length,
      burstPhotos:       groups.where((g) => g.category == PhotoCategory.burst).expand((g) => g.photos).length,
      totalStorageBytes: allPhotos.fold(0, (s, p) => s + p.sizeBytes),
      reclaimableBytes:  reclaimable.fold(0, (s, p) => s + p.sizeBytes),
      lastScanTime:      DateTime.now(),
    );
  }

  Future<void> dispose() async {
    await _scanner.dispose();
  }
}

/// Result of a delete operation.
class DeleteResult {
  const DeleteResult({
    required this.deletedCount,
    required this.freedBytes,
    this.failedIds = const [],
  });

  final int         deletedCount;
  final int         freedBytes;
  final List<String> failedIds;

  String get formattedFreedBytes {
    if (freedBytes < 1048576)    return '${(freedBytes / 1024).toStringAsFixed(1)} KB';
    if (freedBytes < 1073741824) return '${(freedBytes / 1048576).toStringAsFixed(1)} MB';
    return '${(freedBytes / 1073741824).toStringAsFixed(2)} GB';
  }

  bool get hasFailures => failedIds.isNotEmpty;
}
