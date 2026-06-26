---
name: Flutter project in pnpm workspace
description: How Flutter apps are handled when the workspace is a pnpm monorepo with no Flutter artifact type.
---

Flutter apps cannot be scaffolded via `createArtifact` (no Flutter artifact type exists). Generate all project files directly under `artifacts/<slug>/` as a standalone Flutter project directory. No workflow or artifact.toml is created — the user builds/runs via `flutter run` in their own Flutter environment.

**Why:** The artifact system only supports expo, react-vite, mockup-sandbox, slides, video-js. Flutter uses Dart/Gradle and is incompatible with the pnpm workflow infrastructure.

**How to apply:** Write pubspec.yaml, android/ config, and all lib/ Dart files directly. Provide a README with `flutter pub get` and `flutter run` instructions. No `createArtifact()` call needed.
