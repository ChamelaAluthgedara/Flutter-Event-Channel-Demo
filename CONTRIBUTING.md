# Contributing to Flutter Event Channel Demo

Thank you for your interest in contributing to this project! This repository is designed to teach clean, safe, and performant native `EventChannel` streaming in Flutter.

---

## 1. Local Development Setup

To set up the development environment:

1. **Prerequisites:**
   * Flutter SDK (Version >= 3.0.0)
   * Android SDK & JDK 17 (for Android changes)
   * Xcode & CocoaPods (for iOS changes, macOS only)
2. **Setup Commands:**
   * Clone the repository:
     ```bash
     git clone https://github.com/ChamelaAluthgedara/Flutter-Event-Channel-Demo.git
     cd Flutter-Event-Channel-Demo
     ```
   * Retrieve packages and check setup:
     ```bash
     flutter pub get
     flutter doctor
     ```

---

## 2. Branch Naming Conventions

Always create a descriptive branch for your contributions:
* `feat/` for new features (e.g. `feat/sensor-stream`)
* `fix/` for bug fixes (e.g. `fix/android-memory-leak`)
* `docs/` for documentation updates (e.g. `docs/add-troubleshooting`)
* `test/` for testing changes (e.g. `test/add-model-coverage`)
* `chore/` for build scripts, configs, dependencies (e.g. `chore/upgrade-dependencies`)

---

## 3. Code Style and Quality Checks

We enforce clean formatting and static analysis rules to maintain code quality:

* **Formatting:** Run the Dart formatter prior to committing changes:
  ```bash
  dart format .
  ```
* **Linting:** Run static analysis to catch syntax issues, deprecated APIs, and design rule violations:
  ```bash
  flutter analyze
  ```

---

## 4. Test Expectations

Every functional modification or additions to the codebase **must** be accompanied by tests:
* Model changes must have unit tests under `test/`.
* UI or controller updates must have widget/unit tests under `test/`.
* Running tests locally:
  * Flutter/Dart tests: `flutter test`
  * Android JVM tests: `cd android && ./gradlew testDebugUnitTest`

---

## 5. Commit Messaging Guidelines

We strictly follow the [Conventional Commits](https://www.conventionalcommits.org/) standard. Commits should use the format:
```text
<type>(<scope>): <description>
```

### Allowed Types:
* `feat`: A new feature
* `fix`: A bug fix
* `docs`: Documentation changes
* `test`: Adding missing tests or correcting existing tests
* `build`: Changes that affect the build system or external dependencies
* `ci`: Changes to CI configuration files and scripts
* `chore`: Other changes that don't modify src or test files

### Example Commit:
`feat(stream): support configurable native progress events`
