import 'dart:async';
import '../models/photo_model.dart';
import '../models/photo_group_model.dart';
import 'media_store_service.dart';
import 'duplicate_detection_service.dart';
import 'ai_analysis_service.dart';
import '../../core/constants/app_constants.dart';

/// Scan state — updated as the scanner progresses.
enum ScanStatus {
  idle,
  requestingPermission,
  loadingPhotos,
  computingHashes,
  detectingDuplicates,
  analyzingQuality,
  done,
  paused,
  error,
}

/// Immutable snapshot of the current scan progress.
class ScanProgress {
  const ScanProgress({
    this.status = ScanStatus.idle,
    this.photosLoaded = 0,
    this.totalPhotos = 0,
    this.photosAnalyzed = 0,
    this.groupsFound = 0,
    this.currentPhotoName = '',
    this.errorMessage,
  });

  final ScanStatus status;
  final int photosLoaded;
  final int totalPhotos;
  final int photosAnalyzed;
  final int groupsFound;
  final String currentPhotoName;
  final String? errorMessage;

  double get loadProgress =>
      totalPhotos == 0 ? 0.0 : (photosLoaded / totalPhotos).clamp(0.0, 1.0);

  double get analysisProgress =>
      totalPhotos == 0 ? 0.0 : (photosAnalyzed / totalPhotos).clamp(0.0, 1.0);

  String get statusLabel {
    switch (status) {
      case ScanStatus.idle:                 return 'Ready to scan';
      case ScanStatus.requestingPermission: return 'Requesting permission…';
      case ScanStatus.loadingPhotos:        return 'Loading photos…';
      case ScanStatus.computingHashes:      return 'Computing fingerprints…';
      case ScanStatus.detectingDuplicates:  return 'Detecting duplicates…';
      case ScanStatus.analyzingQuality:     return 'Analyzing photo quality…';
      case ScanStatus.done:                 return 'Scan complete';
      case ScanStatus.paused:               return 'Paused';
      case ScanStatus.error:                return 'Error: ${errorMessage ?? 'Unknown'}';
    }
  }

  ScanProgress copyWith({
    ScanStatus? status,
    int? photosLoaded,
    int? totalPhotos,
    int? photosAnalyzed,
    int? groupsFound,
    String? currentPhotoName,
    String? errorMessage,
  }) {
    return ScanProgress(
      status:           status           ?? this.status,
      photosLoaded:     photosLoaded     ?? this.photosLoaded,
      totalPhotos:      totalPhotos      ?? this.totalPhotos,
      photosAnalyzed:   photosAnalyzed   ?? this.photosAnalyzed,
      groupsFound:      groupsFound      ?? this.groupsFound,
      currentPhotoName: currentPhotoName ?? this.currentPhotoName,
      errorMessage:     errorMessage     ?? this.errorMessage,
    );
  }
}

/// Orchestrates the full photo scanning pipeline:
///  1. Request permission.
///  2. Load all photos from MediaStore.
///  3. Compute perceptual hashes.
///  4. Detect duplicate/similar groups.
///  5. AI quality analysis per photo.
///  6. Emit results via StreamController.
class ScannerService {
  final _mediaStore      = MediaStoreService();
  final _duplicateSvc    = DuplicateDetectionService();
  final _aiSvc           = AiAnalysisService();

  final _progressController = StreamController<ScanProgress>.broadcast();
  final _groupController    = StreamController<List<PhotoGroupModel>>.broadcast();

  Stream<ScanProgress>       get progressStream => _progressController.stream;
  Stream<List<PhotoGroupModel>> get groupStream  => _groupController.stream;

  ScanProgress _progress = const ScanProgress();
  bool _paused   = false;
  bool _cancelled = false;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Start a full scan. Emits progress via [progressStream] and
  /// final groups via [groupStream].
  Future<void> startScan() async {
    _paused    = false;
    _cancelled = false;
    _emit(const ScanProgress(status: ScanStatus.requestingPermission));

    // 1. Permission
    final hasPermission = await _mediaStore.requestPermission();
    if (!hasPermission) {
      _emit(_progress.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Gallery permission denied. Please grant access in Settings.',
      ));
      return;
    }

    // 2. Load photos
    _emit(_progress.copyWith(status: ScanStatus.loadingPhotos, photosLoaded: 0));
    final photos = await _mediaStore.loadAllPhotos(
      onProgress: (loaded, total) {
        _emit(_progress.copyWith(
          status: ScanStatus.loadingPhotos,
          photosLoaded: loaded,
          totalPhotos: total,
        ));
      },
    );

    if (_cancelled) return;
    _emit(_progress.copyWith(
      status: ScanStatus.computingHashes,
      totalPhotos: photos.length,
    ));

    // 3. Detect duplicates (includes hash computation)
    if (_cancelled) return;
    _emit(_progress.copyWith(status: ScanStatus.detectingDuplicates));

    final groups = await _duplicateSvc.detectGroups(
      photos,
      onProgress: (processed, total) {
        _emit(_progress.copyWith(
          status: ScanStatus.detectingDuplicates,
          photosAnalyzed: processed,
          totalPhotos: total,
          groupsFound: _progress.groupsFound,
        ));
      },
    );

    if (_cancelled) return;

    // 4. AI quality analysis per photo — process in batches
    _emit(_progress.copyWith(
      status: ScanStatus.analyzingQuality,
      groupsFound: groups.length,
      photosAnalyzed: 0,
    ));

    final analyzedGroups = await _analyzeGroupsQuality(groups);

    if (_cancelled) return;

    // 5. Done — publish final groups
    _groupController.add(analyzedGroups);
    _emit(_progress.copyWith(
      status: ScanStatus.done,
      groupsFound: analyzedGroups.length,
      photosAnalyzed: photos.length,
    ));
  }

  /// Pause scanning after the current photo completes.
  void pause() {
    _paused = true;
    _emit(_progress.copyWith(status: ScanStatus.paused));
  }

  /// Resume a paused scan.
  void resume() {
    _paused = false;
    _emit(_progress.copyWith(status: ScanStatus.analyzingQuality));
  }

  /// Cancel the current scan.
  void cancel() {
    _cancelled = true;
    _paused    = false;
  }

  // ── Quality analysis pass ─────────────────────────────────────────────────

  Future<List<PhotoGroupModel>> _analyzeGroupsQuality(
    List<PhotoGroupModel> groups,
  ) async {
    final updatedGroups = <PhotoGroupModel>[];
    int analyzed = 0;
    final totalToAnalyze = groups.fold<int>(0, (s, g) => s + g.photos.length);

    for (final group in groups) {
      if (_cancelled) break;

      final updatedPhotos = <PhotoModel>[];

      for (final photo in group.photos) {
        // Pause support — poll flag between photos
        while (_paused && !_cancelled) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
        if (_cancelled) break;

        final quality = await _aiSvc.analyzePhoto(photo.path);
        updatedPhotos.add(photo.copyWith(quality: quality));

        analyzed++;
        _emit(_progress.copyWith(
          photosAnalyzed:   analyzed,
          totalPhotos:      totalToAnalyze,
          currentPhotoName: photo.name,
          groupsFound:      groups.length,
        ));
      }

      // Re-rank best photo now that quality scores are available
      final rankedGroup = _rerankBestPhoto(
        group.copyWith(photos: updatedPhotos),
      );
      updatedGroups.add(rankedGroup);

      // Stream partial results so UI can update incrementally
      _groupController.add(updatedGroups);
    }

    return updatedGroups;
  }

  /// After AI analysis, re-select the best photo in each group using
  /// the real quality scores and update deletion suggestions.
  PhotoGroupModel _rerankBestPhoto(PhotoGroupModel group) {
    if (group.photos.length < 2) return group;

    final sorted = [...group.photos]
      ..sort((a, b) => b.quality.overallScore.compareTo(a.quality.overallScore));
    final best = sorted.first;

    final updated = group.photos.map((p) {
      final isBest    = p.id == best.id;
      final reasons   = isBest ? <DeletionReason>[] : _buildReasons(p, best, group.category);
      return p.copyWith(
        isBestInGroup:          isBest,
        isSuggestedForDeletion: !isBest,
        deletionReasons:        reasons,
      );
    }).toList();

    return group.copyWith(photos: updated, bestPhotoId: best.id);
  }

  List<DeletionReason> _buildReasons(
    PhotoModel photo,
    PhotoModel best,
    PhotoCategory category,
  ) {
    final reasons = <DeletionReason>{};

    if (category == PhotoCategory.duplicate) reasons.add(DeletionReason.exactDuplicate);
    if (category == PhotoCategory.burst)     reasons.add(DeletionReason.burst);
    if (category == PhotoCategory.whatsApp)  reasons.add(DeletionReason.whatsAppDuplicate);

    reasons.addAll(photo.quality.deletionReasons);

    if (photo.quality.overallScore < best.quality.overallScore - 0.05) {
      reasons.add(DeletionReason.lowerQuality);
    }

    return reasons.toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _emit(ScanProgress progress) {
    _progress = progress;
    if (!_progressController.isClosed) _progressController.add(progress);
  }

  Future<void> dispose() async {
    await _aiSvc.dispose();
    await _progressController.close();
    await _groupController.close();
  }
}
