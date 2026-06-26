import 'package:flutter/foundation.dart';

/// Deletion/suggestion reason codes — used to explain why a photo is flagged.
enum DeletionReason {
  exactDuplicate,
  lowerQuality,
  eyesClosed,
  blurry,
  motionBlur,
  cameraShake,
  lowResolution,
  poorLighting,
  underexposed,
  overexposed,
  highNoise,
  outOfFocus,
  personEnteredFrame,
  objectBlockingSubject,
  photobomber,
  croppedFace,
  cutOffBody,
  mouthOpen,
  headTurned,
  notSmiling,
  worstComposition,
  worstInGroup,
  screenshot,
  downloaded,
  whatsAppDuplicate,
  burst,
}

/// Human-readable explanations for each deletion reason.
extension DeletionReasonLabel on DeletionReason {
  String get label {
    switch (this) {
      case DeletionReason.exactDuplicate:       return 'Exact duplicate';
      case DeletionReason.lowerQuality:         return 'Lower quality than another photo';
      case DeletionReason.eyesClosed:           return 'Eyes closed';
      case DeletionReason.blurry:               return 'Blurry';
      case DeletionReason.motionBlur:           return 'Motion blur';
      case DeletionReason.cameraShake:          return 'Camera shake';
      case DeletionReason.lowResolution:        return 'Low resolution';
      case DeletionReason.poorLighting:         return 'Poor lighting';
      case DeletionReason.underexposed:         return 'Underexposed (too dark)';
      case DeletionReason.overexposed:          return 'Overexposed (too bright)';
      case DeletionReason.highNoise:            return 'High noise / grain';
      case DeletionReason.outOfFocus:           return 'Out of focus';
      case DeletionReason.personEnteredFrame:   return 'Person entering the frame';
      case DeletionReason.objectBlockingSubject:return 'Object blocking the subject';
      case DeletionReason.photobomber:          return 'Photobomber detected';
      case DeletionReason.croppedFace:          return 'Face is cropped or cut off';
      case DeletionReason.cutOffBody:           return 'Body is partially cut off';
      case DeletionReason.mouthOpen:            return 'Mouth open awkwardly';
      case DeletionReason.headTurned:           return 'Head turned away from camera';
      case DeletionReason.notSmiling:           return 'Not smiling';
      case DeletionReason.worstComposition:     return 'Worse composition';
      case DeletionReason.worstInGroup:         return 'Worse than similar photo';
      case DeletionReason.screenshot:           return 'Screenshot';
      case DeletionReason.downloaded:           return 'Downloaded image';
      case DeletionReason.whatsAppDuplicate:    return 'WhatsApp duplicate';
      case DeletionReason.burst:                return 'Burst photo (not the best)';
    }
  }

  String get icon {
    switch (this) {
      case DeletionReason.exactDuplicate:        return '🔁';
      case DeletionReason.lowerQuality:          return '📉';
      case DeletionReason.eyesClosed:            return '😑';
      case DeletionReason.blurry:                return '🌫️';
      case DeletionReason.motionBlur:            return '💨';
      case DeletionReason.cameraShake:           return '📳';
      case DeletionReason.lowResolution:         return '📐';
      case DeletionReason.poorLighting:          return '🌑';
      case DeletionReason.underexposed:          return '🌑';
      case DeletionReason.overexposed:           return '☀️';
      case DeletionReason.highNoise:             return '📡';
      case DeletionReason.outOfFocus:            return '🔍';
      case DeletionReason.personEnteredFrame:    return '🚶';
      case DeletionReason.objectBlockingSubject: return '🚫';
      case DeletionReason.photobomber:           return '👻';
      case DeletionReason.croppedFace:           return '✂️';
      case DeletionReason.cutOffBody:            return '✂️';
      case DeletionReason.mouthOpen:             return '😮';
      case DeletionReason.headTurned:            return '↩️';
      case DeletionReason.notSmiling:            return '😐';
      case DeletionReason.worstComposition:      return '🖼️';
      case DeletionReason.worstInGroup:          return '👎';
      case DeletionReason.screenshot:            return '📸';
      case DeletionReason.downloaded:            return '⬇️';
      case DeletionReason.whatsAppDuplicate:     return '💬';
      case DeletionReason.burst:                 return '⚡';
    }
  }
}

/// Category of photo group.
enum PhotoCategory {
  duplicate,
  similar,
  burst,
  screenshot,
  whatsApp,
  download,
  edited,
  resized,
}

/// AI quality analysis result for a single photo.
@immutable
class QualityAnalysis {
  const QualityAnalysis({
    this.sharpnessScore = 0.5,
    this.blurScore = 0.0,
    this.motionBlurScore = 0.0,
    this.cameraShakeScore = 0.0,
    this.brightnessScore = 0.5,
    this.exposureScore = 0.5,
    this.noiseScore = 0.0,
    this.colorQualityScore = 0.5,
    this.resolutionScore = 0.5,
    this.overallScore = 0.5,
    this.faceCount = 0,
    this.eyesOpen = true,
    this.isBlinking = false,
    this.smileScore = 0.0,
    this.lookingAtCamera = true,
    this.mouthOpenAwkwardly = false,
    this.headPositionScore = 1.0,
    this.hasCroppedFace = false,
    this.hasCutOffBody = false,
    this.hasPersonEnteringFrame = false,
    this.hasPhotobomber = false,
    this.hasBlockingObject = false,
    this.compositionScore = 0.5,
    this.analysisComplete = false,
  });

  // Sharpness / blur
  final double sharpnessScore;       // 0 (very blurry) → 1 (very sharp)
  final double blurScore;            // 0 (no blur) → 1 (extremely blurry)
  final double motionBlurScore;      // 0 (none) → 1 (severe)
  final double cameraShakeScore;     // 0 (none) → 1 (severe)

  // Lighting / exposure
  final double brightnessScore;      // 0 (very dark) → 1 (very bright)
  final double exposureScore;        // 0 (severe issues) → 1 (perfect)
  final double noiseScore;           // 0 (no noise) → 1 (extreme noise)
  final double colorQualityScore;    // 0 (bad) → 1 (vivid/accurate)

  // Technical
  final double resolutionScore;      // Normalized against group max resolution
  final double overallScore;         // Weighted composite [0–1]

  // Face / people analysis
  final int    faceCount;
  final bool   eyesOpen;
  final bool   isBlinking;
  final double smileScore;           // 0 (not smiling) → 1 (big smile)
  final bool   lookingAtCamera;
  final bool   mouthOpenAwkwardly;
  final double headPositionScore;    // 0 (fully turned) → 1 (facing forward)
  final bool   hasCroppedFace;
  final bool   hasCutOffBody;

  // Scene / composition
  final bool   hasPersonEnteringFrame;
  final bool   hasPhotobomber;
  final bool   hasBlockingObject;
  final double compositionScore;     // 0 (bad) → 1 (excellent)

  /// Whether ML analysis has completed for this photo.
  final bool   analysisComplete;

  /// Collect all active deletion reasons based on scores.
  List<DeletionReason> get deletionReasons {
    final reasons = <DeletionReason>[];
    if (blurScore > 0.60)               reasons.add(DeletionReason.blurry);
    if (motionBlurScore > 0.50)         reasons.add(DeletionReason.motionBlur);
    if (cameraShakeScore > 0.50)        reasons.add(DeletionReason.cameraShake);
    if (brightnessScore < 0.25)         reasons.add(DeletionReason.underexposed);
    if (brightnessScore > 0.85)         reasons.add(DeletionReason.overexposed);
    if (noiseScore > 0.65)              reasons.add(DeletionReason.highNoise);
    if (faceCount > 0 && !eyesOpen)     reasons.add(DeletionReason.eyesClosed);
    if (faceCount > 0 && isBlinking)    reasons.add(DeletionReason.eyesClosed);
    if (faceCount > 0 && mouthOpenAwkwardly) reasons.add(DeletionReason.mouthOpen);
    if (faceCount > 0 && !lookingAtCamera)   reasons.add(DeletionReason.headTurned);
    if (hasCroppedFace)                 reasons.add(DeletionReason.croppedFace);
    if (hasCutOffBody)                  reasons.add(DeletionReason.cutOffBody);
    if (hasPersonEnteringFrame)         reasons.add(DeletionReason.personEnteredFrame);
    if (hasPhotobomber)                 reasons.add(DeletionReason.photobomber);
    if (hasBlockingObject)              reasons.add(DeletionReason.objectBlockingSubject);
    if (compositionScore < 0.30)        reasons.add(DeletionReason.worstComposition);
    return reasons;
  }

  QualityAnalysis copyWith({
    double? sharpnessScore,
    double? blurScore,
    double? motionBlurScore,
    double? cameraShakeScore,
    double? brightnessScore,
    double? exposureScore,
    double? noiseScore,
    double? colorQualityScore,
    double? resolutionScore,
    double? overallScore,
    int?    faceCount,
    bool?   eyesOpen,
    bool?   isBlinking,
    double? smileScore,
    bool?   lookingAtCamera,
    bool?   mouthOpenAwkwardly,
    double? headPositionScore,
    bool?   hasCroppedFace,
    bool?   hasCutOffBody,
    bool?   hasPersonEnteringFrame,
    bool?   hasPhotobomber,
    bool?   hasBlockingObject,
    double? compositionScore,
    bool?   analysisComplete,
  }) {
    return QualityAnalysis(
      sharpnessScore:        sharpnessScore        ?? this.sharpnessScore,
      blurScore:             blurScore             ?? this.blurScore,
      motionBlurScore:       motionBlurScore        ?? this.motionBlurScore,
      cameraShakeScore:      cameraShakeScore      ?? this.cameraShakeScore,
      brightnessScore:       brightnessScore       ?? this.brightnessScore,
      exposureScore:         exposureScore         ?? this.exposureScore,
      noiseScore:            noiseScore            ?? this.noiseScore,
      colorQualityScore:     colorQualityScore     ?? this.colorQualityScore,
      resolutionScore:       resolutionScore       ?? this.resolutionScore,
      overallScore:          overallScore          ?? this.overallScore,
      faceCount:             faceCount             ?? this.faceCount,
      eyesOpen:              eyesOpen              ?? this.eyesOpen,
      isBlinking:            isBlinking            ?? this.isBlinking,
      smileScore:            smileScore            ?? this.smileScore,
      lookingAtCamera:       lookingAtCamera       ?? this.lookingAtCamera,
      mouthOpenAwkwardly:    mouthOpenAwkwardly    ?? this.mouthOpenAwkwardly,
      headPositionScore:     headPositionScore     ?? this.headPositionScore,
      hasCroppedFace:        hasCroppedFace        ?? this.hasCroppedFace,
      hasCutOffBody:         hasCutOffBody         ?? this.hasCutOffBody,
      hasPersonEnteringFrame:hasPersonEnteringFrame ?? this.hasPersonEnteringFrame,
      hasPhotobomber:        hasPhotobomber        ?? this.hasPhotobomber,
      hasBlockingObject:     hasBlockingObject     ?? this.hasBlockingObject,
      compositionScore:      compositionScore      ?? this.compositionScore,
      analysisComplete:      analysisComplete      ?? this.analysisComplete,
    );
  }
}

/// Represents a single photo on the device.
class PhotoModel {
  const PhotoModel({
    required this.id,
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.dateCreated,
    required this.dateModified,
    this.mimeType = 'image/jpeg',
    this.bucketName = '',
    this.bucketId = '',
    this.pHash = '',
    this.quality = const QualityAnalysis(),
    this.isBestInGroup = false,
    this.isSuggestedForDeletion = false,
    this.isSelected = false,
    this.category = PhotoCategory.similar,
    this.groupId,
    this.deletionReasons = const [],
  });

  final String   id;             // MediaStore ID
  final String   path;           // Absolute file path
  final String   name;           // File name
  final int      sizeBytes;      // File size in bytes
  final int      width;          // Pixel width
  final int      height;         // Pixel height
  final DateTime dateCreated;
  final DateTime dateModified;
  final String   mimeType;
  final String   bucketName;     // Album name (e.g. "Camera", "WhatsApp Images")
  final String   bucketId;

  // Analysis
  final String          pHash;       // 64-bit perceptual hash hex string
  final QualityAnalysis quality;

  // Group membership
  final bool             isBestInGroup;
  final bool             isSuggestedForDeletion;
  final bool             isSelected;          // User-selected for deletion
  final PhotoCategory    category;
  final String?          groupId;
  final List<DeletionReason> deletionReasons;

  // ── Derived helpers ────────────────────────────────────────────────────────
  String get formattedSize {
    if (sizeBytes < 1024)       return '$sizeBytes B';
    if (sizeBytes < 1048576)    return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
  }

  String get resolution => '${width}×$height';

  bool get isWhatsApp => bucketName.toLowerCase().contains('whatsapp');
  bool get isScreenshot =>
      bucketName.toLowerCase().contains('screenshot') ||
      name.toLowerCase().contains('screenshot');
  bool get isDownload => bucketName.toLowerCase().contains('download');
  bool get isCamera    => bucketName.toLowerCase().contains('camera');

  PhotoModel copyWith({
    String?             id,
    String?             path,
    String?             name,
    int?                sizeBytes,
    int?                width,
    int?                height,
    DateTime?           dateCreated,
    DateTime?           dateModified,
    String?             mimeType,
    String?             bucketName,
    String?             bucketId,
    String?             pHash,
    QualityAnalysis?    quality,
    bool?               isBestInGroup,
    bool?               isSuggestedForDeletion,
    bool?               isSelected,
    PhotoCategory?      category,
    String?             groupId,
    List<DeletionReason>? deletionReasons,
  }) {
    return PhotoModel(
      id:                    id                    ?? this.id,
      path:                  path                  ?? this.path,
      name:                  name                  ?? this.name,
      sizeBytes:             sizeBytes             ?? this.sizeBytes,
      width:                 width                 ?? this.width,
      height:                height                ?? this.height,
      dateCreated:           dateCreated           ?? this.dateCreated,
      dateModified:          dateModified          ?? this.dateModified,
      mimeType:              mimeType              ?? this.mimeType,
      bucketName:            bucketName            ?? this.bucketName,
      bucketId:              bucketId              ?? this.bucketId,
      pHash:                 pHash                 ?? this.pHash,
      quality:               quality               ?? this.quality,
      isBestInGroup:         isBestInGroup         ?? this.isBestInGroup,
      isSuggestedForDeletion:isSuggestedForDeletion?? this.isSuggestedForDeletion,
      isSelected:            isSelected            ?? this.isSelected,
      category:              category              ?? this.category,
      groupId:               groupId               ?? this.groupId,
      deletionReasons:       deletionReasons       ?? this.deletionReasons,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PhotoModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
