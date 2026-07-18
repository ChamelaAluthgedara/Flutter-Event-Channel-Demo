# Project Roadmap

This document outlines the planned future roadmap, upcoming stream examples, and testing expansions for the Flutter Event Channel Demo project.

---

## 1. Upcoming Native Event Stream Examples

We plan to expand this educational repository with additional permission-free or permission-scoped native stream examples:

- [ ] **Sensor Telemetry Stream:** Stream real-time hardware sensor readings (Accelerometer and Gyroscope data) from native host sensors to Dart.
- [ ] **Location Stream:** Implement real-time GPS location tracking on Android and iOS (detailing permission handling inside platform channels).
- [ ] **Native Network Connectivity:** Stream network status changes (Wi-Fi, Mobile Data, Offline) observed via native listeners.

---

## 2. Testing Expansions

To ensure high-quality integrations, we plan to expand test coverage on both Dart and Native hosts:

- [ ] **iOS Swift Unit Tests:** Set up XCTest coverage for `ProgressStreamHandler` and `BatteryStreamHandler` in Swift.
- [ ] **Native Android Test Refinement:** Expand JUnit tests for native BroadcastReceiver bindings using Robolectric.
- [ ] **Device Farm Integration Testing:** Integrate Firebase Test Lab or GitHub Actions macOS runners to execute integration tests on real/virtual hardware instead of mock binary messenger envelopes.

---

## 3. Multi-Platform Support

Event channels are supported on all Flutter targets. We plan to expand the demo to:
- [ ] **macOS Support:** Swift-based EventChannel streaming.
- [ ] **Windows Support:** C++-based EventChannel streaming.
- [ ] **Web Support:** Event-stream simulation or Web worker event listeners.

---

## 4. Community Contributions

We welcome proposals and contributions from the community! Feel free to open a feature request if you have ideas on:
* Standardized abstract wrappers for stream handlers.
* Integration recipes with State Management libraries (Bloc, Riverpod, Provider).
