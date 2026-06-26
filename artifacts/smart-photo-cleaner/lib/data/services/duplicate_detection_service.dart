import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../models/photo_model.dart';
import '../models/photo_group_model.dart';
import '../../core/constants/app_constants.dart';
import 'perceptual_hash_service.dart';

/// Detects exact and similar photos using:
///  - MD5 hash for exact byte-level duplicates.
///  - Perceptual hash (pHash) for similar / burst / edited / resized copies.
///  - Metadata analysis for WhatsApp re-saves, screenshots, and downloads.
///
/// All processing is local — no network calls.
class DuplicateDetectionService {
  final PerceptualHashService _pHashService = PerceptualHashService();

  /// Process a list of photos, group duplicates/similars, and return groups.
  ///
  /// Steps:
  ///  1. Compute MD5 → group exact duplicates.
  ///  2. Compute pHash → group similar / burst / edited / resized.
  ///  3. Tag screenshots, WhatsApp, and downloads via metadata.
  ///  4. Build [PhotoGroupModel] for each group.
  Future<List<PhotoGroupModel>> detectGroups(
    List<PhotoModel> photos, {
    void Function(int processed, int total)? onProgress,
  }) async {
    final total = photos.length;
    int processed = 0;

    // ── Step 1: Exact duplicates via MD5 ─────────────────────────────────
    final md5Groups = <String, List<PhotoModel>>{};
    final pHashMap  = <String, String>{}; // photoId → pHash

    for (final photo in photos) {
      final md5 = await _computeMd5(photo.path);
      if (md5.isNotEmpty) {
        md5Groups.putIfAbsent(md5, () => []).add(photo);
      }

      // Compute pHash in the same pass
      final pHash = await _computePHash(photo.path);
      if (pHash.isNotEmpty) {
        pHashMap[photo.id] = pHash;
      }

      processed++;
      onProgress?.call(processed, total);
    }

    final groups = <PhotoGroupModel>[];
    final assignedIds = <String>{};
    int groupIndex = 0;

    // Create groups for exact MD5 duplicates
    for (final entry in md5Groups.entries) {
      if (entry.value.length < 2) continue;

      final groupId = 'g${groupIndex++}';
      final groupPhotos = entry.value.map((p) {
        assignedIds.add(p.id);
        return p.copyWith(
          groupId:  groupId,
          pHash:    pHashMap[p.id] ?? '',
          category: PhotoCategory.duplicate,
        );
      }).toList();

      groups.add(_buildGroup(
        id:       groupId,
        photos:   groupPhotos,
        category: PhotoCategory.duplicate,
      ));
    }

    // ── Step 2: Similar photos via pHash ──────────────────────────────────
    final unassigned = photos.where((p) => !assignedIds.contains(p.id)).toList();
    final pHashGroups = _clusterByPHash(unassigned, pHashMap);

    for (final cluster in pHashGroups) {
      if (cluster.length < 2) continue;

      final category = _inferCategory(cluster);
      final groupId  = 'g${groupIndex++}';
      final groupPhotos = cluster.map((p) {
        assignedIds.add(p.id);
        return p.copyWith(
          groupId:  groupId,
          pHash:    pHashMap[p.id] ?? '',
          category: category,
        );
      }).toList();

      groups.add(_buildGroup(
        id:       groupId,
        photos:   groupPhotos,
        category: category,
      ));
    }

    // ── Step 3: Single-photo special categories ───────────────────────────
    // Screenshots / WhatsApp / Downloads — group by album even if not duplicates
    final specialSingles = photos
        .where((p) => !assignedIds.contains(p.id))
        .where((p) => p.isScreenshot || p.isWhatsApp || p.isDownload)
        .toList();

    final screenshotGroup = specialSingles.where((p) => p.isScreenshot).toList();
    final whatsappGroup   = specialSingles.where((p) => p.isWhatsApp).toList();
    final downloadGroup   = specialSingles.where((p) => p.isDownload).toList();

    if (screenshotGroup.isNotEmpty) {
      final gId = 'g${groupIndex++}';
      groups.add(PhotoGroupModel(
        id:       gId,
        photos:   screenshotGroup.map((p) => p.copyWith(groupId: gId, category: PhotoCategory.screenshot)).toList(),
        category: PhotoCategory.screenshot,
      ));
    }

    if (whatsappGroup.isNotEmpty) {
      final gId = 'g${groupIndex++}';
      groups.add(PhotoGroupModel(
        id:       gId,
        photos:   whatsappGroup.map((p) => p.copyWith(groupId: gId, category: PhotoCategory.whatsApp)).toList(),
        category: PhotoCategory.whatsApp,
      ));
    }

    if (downloadGroup.isNotEmpty) {
      final gId = 'g${groupIndex++}';
      groups.add(PhotoGroupModel(
        id:       gId,
        photos:   downloadGroup.map((p) => p.copyWith(groupId: gId, category: PhotoCategory.download)).toList(),
        category: PhotoCategory.download,
      ));
    }

    return groups;
  }

  // ── Clustering ────────────────────────────────────────────────────────────

  /// Union-Find clustering of photos by pHash Hamming distance.
  List<List<PhotoModel>> _clusterByPHash(
    List<PhotoModel> photos,
    Map<String, String> pHashMap,
  ) {
    final n = photos.length;
    if (n == 0) return [];

    // Union-Find
    final parent = List.generate(n, (i) => i);
    int find(int x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]]; // path compression
        x = parent[x];
      }
      return x;
    }
    void union(int x, int y) {
      parent[find(x)] = find(y);
    }

    // Compare every pair — O(n²) but runs on a background isolate
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final h1 = pHashMap[photos[i].id] ?? '';
        final h2 = pHashMap[photos[j].id] ?? '';
        if (h1.isEmpty || h2.isEmpty) continue;

        final dist = PerceptualHashService.hammingDistance(h1, h2);
        if (dist <= AppConstants.pHashSimilarThreshold) {
          union(i, j);
        }
      }
    }

    // Collect clusters
    final clusters = <int, List<PhotoModel>>{};
    for (int i = 0; i < n; i++) {
      clusters.putIfAbsent(find(i), () => []).add(photos[i]);
    }

    return clusters.values.toList();
  }

  /// Infer the best category for a pHash cluster.
  PhotoCategory _inferCategory(List<PhotoModel> photos) {
    // Burst: many photos taken within seconds of each other
    final times = photos.map((p) => p.dateCreated.millisecondsSinceEpoch).toList()..sort();
    final timeSpanSeconds = (times.last - times.first) / 1000;
    if (photos.length >= 3 && timeSpanSeconds < 10) return PhotoCategory.burst;

    // WhatsApp re-saves
    if (photos.any((p) => p.isWhatsApp)) return PhotoCategory.whatsApp;

    // Resized: same photo but very different resolutions
    final sizes = photos.map((p) => p.width * p.height).toList();
    final minSize = sizes.reduce((a, b) => a < b ? a : b);
    final maxSize = sizes.reduce((a, b) => a > b ? a : b);
    if (maxSize > minSize * 2) return PhotoCategory.resized;

    // Edited: same scene, small pHash distance, but different timestamps
    if (timeSpanSeconds > 3600) return PhotoCategory.edited;

    return PhotoCategory.similar;
  }

  // ── Build group with best-photo selection ─────────────────────────────────

  PhotoGroupModel _buildGroup({
    required String          id,
    required List<PhotoModel> photos,
    required PhotoCategory   category,
  }) {
    // Sort by overall quality score descending
    final sorted = [...photos]
      ..sort((a, b) => b.quality.overallScore.compareTo(a.quality.overallScore));

    final best = sorted.first;

    final tagged = photos.map((p) {
      final isBest     = p.id == best.id;
      final reasons    = _buildReasons(p, best, category);
      return p.copyWith(
        isBestInGroup:          isBest,
        isSuggestedForDeletion: !isBest,
        deletionReasons:        isBest ? [] : reasons,
      );
    }).toList();

    return PhotoGroupModel(
      id:          id,
      photos:      tagged,
      category:    category,
      bestPhotoId: best.id,
    );
  }

  /// Build list of deletion reasons for a non-best photo.
  List<DeletionReason> _buildReasons(
    PhotoModel photo,
    PhotoModel best,
    PhotoCategory category,
  ) {
    final reasons = <DeletionReason>[];

    // Category-specific reasons first
    switch (category) {
      case PhotoCategory.duplicate:
        reasons.add(DeletionReason.exactDuplicate);
        break;
      case PhotoCategory.whatsApp:
        reasons.add(DeletionReason.whatsAppDuplicate);
        break;
      case PhotoCategory.burst:
        reasons.add(DeletionReason.burst);
        break;
      default:
        break;
    }

    // Quality-based reasons from the analysis
    reasons.addAll(photo.quality.deletionReasons);

    // Generic "lower quality" if no specific reason found
    if (photo.quality.overallScore < best.quality.overallScore - 0.05 &&
        !reasons.contains(DeletionReason.lowerQuality)) {
      reasons.add(DeletionReason.lowerQuality);
    }

    // Deduplicate while preserving order
    return reasons.toSet().toList();
  }

  // ── Hash helpers ──────────────────────────────────────────────────────────

  Future<String> _computeMd5(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return '';
      final bytes = await file.readAsBytes();
      return md5.convert(bytes).toString();
    } catch (_) {
      return '';
    }
  }

  Future<String> _computePHash(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return '';
      final bytes = await file.readAsBytes() as Uint8List;
      return await _pHashService.computeHash(bytes);
    } catch (_) {
      return '';
    }
  }
}
