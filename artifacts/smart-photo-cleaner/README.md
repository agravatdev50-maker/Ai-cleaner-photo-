# Smart Photo Cleaner

An AI-powered Android application built with Flutter that helps users reclaim storage by detecting and removing duplicate, similar, and low-quality photos — **100% on-device, no uploads, fully offline**.

---

## Features

### 🔍 Detection
| Feature | Method |
|---|---|
| Exact duplicates | MD5 hash comparison |
| Similar photos | Perceptual hashing (pHash) — Hamming distance ≤ 6 |
| Burst photos | pHash + timestamp proximity (< 10 seconds) |
| Edited / resized copies | pHash + resolution delta |
| WhatsApp duplicates | Album name detection + pHash |
| Screenshots | Album name / filename detection |
| Downloads | Album name detection |

### 🤖 AI Quality Analysis (ML Kit + image processing)
- Sharpness & blur (Laplacian variance)
- Motion blur (directional gradient asymmetry)
- Camera shake detection
- Brightness & exposure scoring
- Noise estimation (local standard deviation)
- Color quality (saturation analysis)
- Resolution scoring
- Face detection (ML Kit)
- Eye open / closed / blinking (ML Kit classification)
- Smile quality (ML Kit)
- Head pose / looking at camera (ML Kit Euler angles)
- Mouth open awkwardly
- Cropped / cut-off faces
- Photobomber detection (multiple faces)
- Composition scoring (rule of thirds)

### ✨ Smart Recommendations
- Automatically selects the **Best Photo** in each group
- Marks remaining photos as **Suggested for Deletion**
- Provides human-readable reasons per photo:
  - "Eyes closed", "Blurry", "Motion blur", "Low resolution", etc.
- **Never deletes automatically** — always requires user confirmation

### 📊 Dashboard
- Total photos, duplicates, similar, screenshots, WhatsApp, downloads
- Storage used vs. storage that can be freed
- Category quick-navigation cards

### 🎛️ User Controls
- Full-screen photo viewer with pinch-to-zoom and swipe
- Select / deselect individual photos
- Select all suggested photos at once
- Delete review screen showing count + bytes to be freed
- Confirmation dialog before any deletion
- Search photos by filename or album name
- Sort groups by date, size, quality, or count
- Filter to show only suggested photos
- Pause / resume scanning at any time

### ⚙️ Settings
- Light / Dark / System theme
- Auto-select best photo toggle
- Help & FAQ
- About screen with privacy statement

---

## Architecture

```
lib/
├── app/
│   ├── app.dart              ← Root MaterialApp with GoRouter
│   └── router.dart           ← All named routes
├── core/
│   ├── constants/            ← AppConstants (thresholds, keys, weights)
│   ├── theme/                ← Material 3 light + dark themes
│   └── utils/                ← FormatUtils (bytes, dates, scores)
├── data/
│   ├── models/               ← PhotoModel, PhotoGroupModel, QualityAnalysis, ScanStats
│   ├── repositories/         ← PhotoRepository (single source of truth)
│   └── services/
│       ├── media_store_service.dart       ← Android MediaStore via photo_manager
│       ├── perceptual_hash_service.dart   ← pHash + dHash implementation
│       ├── duplicate_detection_service.dart ← MD5 + pHash clustering
│       ├── ai_analysis_service.dart       ← ML Kit + pixel analysis
│       └── scanner_service.dart           ← Full scan pipeline + streaming
└── presentation/
    ├── providers/             ← Riverpod providers
    │   ├── scanner_provider.dart
    │   └── theme_provider.dart
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── dashboard_screen.dart
    │   ├── scanner_screen.dart
    │   ├── photo_groups_screen.dart
    │   ├── photo_viewer_screen.dart
    │   ├── delete_review_screen.dart
    │   ├── settings_screen.dart
    │   ├── help_screen.dart
    │   └── about_screen.dart
    └── widgets/
        ├── group_card.dart
        ├── photo_card.dart
        ├── best_photo_badge.dart
        ├── dashboard_stat_card.dart
        └── scan_progress_widget.dart
```

### State Management
- **Riverpod** (flutter_riverpod 2.x) with `NotifierProvider` for mutable state
- `StreamProvider` for real-time scan progress
- `Provider.family` for per-category filtered groups
- Repository pattern: `PhotoRepository` owns all in-memory state

### Design Pattern
MVVM:
- **Model** → `data/models/`
- **ViewModel** → `presentation/providers/` (Riverpod Notifiers)
- **View** → `presentation/screens/` + `presentation/widgets/`

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI framework | Flutter 3 + Material 3 |
| State management | Riverpod 2 |
| Navigation | GoRouter |
| Photo access | photo_manager (MediaStore API) |
| Permissions | permission_handler |
| Face detection | Google ML Kit Face Detection |
| Image labeling | Google ML Kit Image Labeling |
| Image processing | Dart `image` package |
| Hashing | `crypto` (MD5) + custom pHash |
| Preferences | shared_preferences |
| Animations | flutter_animate |
| Photo viewer | photo_view |

---

## Supported Android Versions

- Android 10 (API 29) through Android 16
- Uses `READ_MEDIA_IMAGES` (Android 13+) and `READ_EXTERNAL_STORAGE` (Android 10–12)
- `MANAGE_MEDIA` for deleting photos not created by the app
- Scoped storage compliant — no `MANAGE_EXTERNAL_STORAGE` required

---

## Getting Started

### Prerequisites
- Flutter 3.19+
- Android Studio / VS Code with Flutter plugin
- Android device or emulator (API 29+)

### Build

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### First Run
1. Grant gallery permission when prompted.
2. Tap **Scan My Photos** on the dashboard.
3. Wait for scanning and AI analysis to complete.
4. Browse detected groups, review suggestions, and selectively delete.

---

## Privacy

- All photo analysis happens on-device using local ML models.
- No photo data, metadata, or analytics are ever sent to any server.
- The app operates fully offline after the initial ML Kit model download.
- Deleted photos go to Android Trash and can be restored within 30 days.
