/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // ── App metadata ─────────────────────────────────────────────────────────
  static const String appName = 'Smart Photo Cleaner';
  static const String version = '1.0.0';

  // ── Scanning ──────────────────────────────────────────────────────────────
  /// Maximum number of photos processed per batch to avoid OOM on large libraries.
  static const int scanBatchSize = 50;

  /// Perceptual hash distance threshold — photos within this Hamming distance
  /// are considered duplicates (0 = identical bits, lower = more strict).
  static const int pHashDuplicateThreshold = 6;

  /// Threshold for "similar" photos (looser than exact duplicate).
  static const int pHashSimilarThreshold = 14;

  /// Maximum thumbnail size (pixels) used for fast pHash computation.
  static const int pHashThumbnailSize = 32;

  // ── Quality scoring weights ───────────────────────────────────────────────
  static const double weightSharpness    = 0.20;
  static const double weightExposure     = 0.12;
  static const double weightResolution   = 0.10;
  static const double weightNoise        = 0.08;
  static const double weightFaceQuality  = 0.20;
  static const double weightComposition  = 0.10;
  static const double weightColorQuality = 0.10;
  static const double weightMotionBlur   = 0.10;

  // ── Thresholds for quality labels ─────────────────────────────────────────
  static const double sharpnessBlurThreshold       = 0.35;
  static const double sharpnessMotionBlurThreshold = 0.25;
  static const double brightnessUnderexposed        = 0.25;
  static const double brightnessOverexposed         = 0.85;

  // ── Face detection ────────────────────────────────────────────────────────
  /// Minimum face confidence to be counted as a detected face.
  static const double faceConfidenceThreshold = 0.80;
  /// Eye open probability threshold — below this counts as "eyes closed".
  static const double eyeOpenThreshold = 0.50;
  /// Smiling probability threshold.
  static const double smileThreshold = 0.50;

  // ── UI ────────────────────────────────────────────────────────────────────
  static const double cardRadius = 16.0;
  static const double tileRadius = 12.0;
  static const Duration animDuration = Duration(milliseconds: 300);
  static const Duration longAnimDuration = Duration(milliseconds: 600);

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String prefThemeMode      = 'theme_mode';
  static const String prefLastScanTime   = 'last_scan_time';
  static const String prefAutoSelectBest = 'auto_select_best';
  static const String prefScanWifiOnly   = 'scan_wifi_only';

  // ── Photo categories ──────────────────────────────────────────────────────
  static const String categoryAll         = 'all';
  static const String categoryDuplicates  = 'duplicates';
  static const String categorySimilar     = 'similar';
  static const String categoryScreenshots = 'screenshots';
  static const String categoryWhatsApp    = 'whatsapp';
  static const String categoryDownloads   = 'downloads';
  static const String categoryBurst       = 'burst';
}
