import 'photo_model.dart';

/// A group of similar or duplicate photos that the scanner has identified.
class PhotoGroupModel {
  const PhotoGroupModel({
    required this.id,
    required this.photos,
    required this.category,
    this.bestPhotoId,
    this.isExpanded = true,
  });

  final String id;
  final List<PhotoModel> photos;
  final PhotoCategory category;
  final String? bestPhotoId;  // ID of the recommended "best" photo
  final bool isExpanded;       // Whether group is expanded in the UI

  // ── Derived helpers ────────────────────────────────────────────────────────

  PhotoModel? get bestPhoto =>
      bestPhotoId != null
          ? photos.where((p) => p.id == bestPhotoId).firstOrNull
          : null;

  List<PhotoModel> get suggestedForDeletion =>
      photos.where((p) => p.isSuggestedForDeletion).toList();

  List<PhotoModel> get selectedPhotos =>
      photos.where((p) => p.isSelected).toList();

  int get totalSizeBytes =>
      photos.fold(0, (sum, p) => sum + p.sizeBytes);

  int get reclaimableSizeBytes =>
      suggestedForDeletion.fold(0, (sum, p) => sum + p.sizeBytes);

  int get selectedSizeBytes =>
      selectedPhotos.fold(0, (sum, p) => sum + p.sizeBytes);

  String get categoryLabel {
    switch (category) {
      case PhotoCategory.duplicate: return 'Exact Duplicate';
      case PhotoCategory.similar:   return 'Similar Photos';
      case PhotoCategory.burst:     return 'Burst Photos';
      case PhotoCategory.screenshot:return 'Screenshots';
      case PhotoCategory.whatsApp:  return 'WhatsApp';
      case PhotoCategory.download:  return 'Downloads';
      case PhotoCategory.edited:    return 'Edited Copy';
      case PhotoCategory.resized:   return 'Resized Copy';
    }
  }

  String get categoryIcon {
    switch (category) {
      case PhotoCategory.duplicate: return '🔁';
      case PhotoCategory.similar:   return '📷';
      case PhotoCategory.burst:     return '⚡';
      case PhotoCategory.screenshot:return '📱';
      case PhotoCategory.whatsApp:  return '💬';
      case PhotoCategory.download:  return '⬇️';
      case PhotoCategory.edited:    return '✏️';
      case PhotoCategory.resized:   return '📐';
    }
  }

  PhotoGroupModel copyWith({
    String?             id,
    List<PhotoModel>?   photos,
    PhotoCategory?      category,
    String?             bestPhotoId,
    bool?               isExpanded,
  }) {
    return PhotoGroupModel(
      id:          id          ?? this.id,
      photos:      photos      ?? this.photos,
      category:    category    ?? this.category,
      bestPhotoId: bestPhotoId ?? this.bestPhotoId,
      isExpanded:  isExpanded  ?? this.isExpanded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PhotoGroupModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Aggregated statistics shown on the dashboard.
class ScanStats {
  const ScanStats({
    this.totalPhotos = 0,
    this.duplicatePhotos = 0,
    this.similarPhotos = 0,
    this.screenshotPhotos = 0,
    this.whatsAppPhotos = 0,
    this.downloadPhotos = 0,
    this.burstPhotos = 0,
    this.totalStorageBytes = 0,
    this.reclaimableBytes = 0,
    this.lastScanTime,
  });

  final int      totalPhotos;
  final int      duplicatePhotos;
  final int      similarPhotos;
  final int      screenshotPhotos;
  final int      whatsAppPhotos;
  final int      downloadPhotos;
  final int      burstPhotos;
  final int      totalStorageBytes;
  final int      reclaimableBytes;
  final DateTime? lastScanTime;

  String get formattedTotalStorage =>
      _formatBytes(totalStorageBytes);

  String get formattedReclaimable =>
      _formatBytes(reclaimableBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024)         return '$bytes B';
    if (bytes < 1048576)      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824)   return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  ScanStats copyWith({
    int?      totalPhotos,
    int?      duplicatePhotos,
    int?      similarPhotos,
    int?      screenshotPhotos,
    int?      whatsAppPhotos,
    int?      downloadPhotos,
    int?      burstPhotos,
    int?      totalStorageBytes,
    int?      reclaimableBytes,
    DateTime? lastScanTime,
  }) {
    return ScanStats(
      totalPhotos:      totalPhotos      ?? this.totalPhotos,
      duplicatePhotos:  duplicatePhotos  ?? this.duplicatePhotos,
      similarPhotos:    similarPhotos    ?? this.similarPhotos,
      screenshotPhotos: screenshotPhotos ?? this.screenshotPhotos,
      whatsAppPhotos:   whatsAppPhotos   ?? this.whatsAppPhotos,
      downloadPhotos:   downloadPhotos   ?? this.downloadPhotos,
      burstPhotos:      burstPhotos      ?? this.burstPhotos,
      totalStorageBytes:totalStorageBytes?? this.totalStorageBytes,
      reclaimableBytes: reclaimableBytes ?? this.reclaimableBytes,
      lastScanTime:     lastScanTime     ?? this.lastScanTime,
    );
  }
}
