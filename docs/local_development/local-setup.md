# Local Development & Verification Guide

> **Setup steps, simulator commands, hermetic verification, and troubleshooting.**

---

## 1. Prerequisites

- **Flutter SDK**: `>=3.19.0`
- **Dart SDK**: `>=3.3.0`
- **Supported Targets**:
  - Android Emulator (API 26+)
  - iOS Simulator (iOS 15+)
  - macOS Desktop (fastest for UI logic feedback)

---

## 2. Setup & Execution

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Verify connected devices
flutter devices

# 3. Run application on target
flutter run -d macos     # macOS desktop
flutter run -d ios       # iOS Simulator
flutter run -d android   # Android Emulator
```

---

## 3. Resetting Local Persistence for Clean Testing

To simulate a brand new install and clear progress:

- **Android Emulator / Device**:
  ```bash
  adb shell pm clear com.example.thaheen_lms
  ```
- **iOS Simulator**:
  ```bash
  xcrun simctl uninstall booted com.example.thaheenLms
  ```
- **macOS Desktop**:
  ```bash
  rm -f ~/Library/Containers/com.example.thaheenLms/Data/Library/Preferences/com.example.thaheenLms.plist
  ```

---

## 4. Running Quality Gates Locally

```bash
# Formatter check
dart format --output=none --set-exit-if-changed .

# Static analysis
flutter analyze --no-pub

# Hermetic offline operation check
flutter test --no-pub test/unit/core/hermetic_offline_network_test.dart

# All unit tests
flutter test --no-pub test/unit/

# All widget tests
flutter test --no-pub test/widget/

# Full suite
flutter test --no-pub
```

---

## 5. Troubleshooting & Gotchas

- **Video Decoder Issues on Android Emulator**:
  - If video freezes or renders black frames on the Android emulator, set the emulator's graphics rendering mode to **Hardware - GLES 2.0** in Android Studio AVD Manager.
- **RTL Text Direction in Tests**:
  - All widget tests rendering localized components must wrap the test widget in `Directionality(textDirection: TextDirection.rtl, child: ...)`.
- **AppLifecycleListener State Transitions**:
  - Transitioning an `AppLifecycleListener` directly from `paused` to `inactive` fails framework assertions. Always transition in strict order: `resumed` $\rightarrow$ `inactive` $\rightarrow$ `hidden` $\rightarrow$ `paused`.
