# Kotlin Migration and Comparison Guide

This document describes the native Kotlin implementation of the `EventChannel` stream handler and provides step-by-step instructions for switching between Java and Kotlin in this demo project.

---

## 1. Switching the Active Implementation

By default, the project is configured to build and compile using the Java implementation of the main activity:
`android/app/src/main/java/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.java`

Since having two main activity definitions in the same package will cause duplicate class conflicts during build, only one file must have the compiling extension (`.java` or `.kt`) while the other uses `.example`.

### To Switch to Kotlin:
1. Rename the Java file to disable it:
   ```bash
   mv android/app/src/main/java/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.java \
      android/app/src/main/java/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.java.example
   ```
2. Rename the Kotlin file to activate it:
   ```bash
   mv android/app/src/main/kotlin/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.kt.example \
      android/app/src/main/kotlin/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.kt
   ```
3. Run `flutter clean` and rebuild the app:
   ```bash
   flutter clean
   flutter run
   ```

### To Switch Back to Java:
1. Rename the Kotlin file to disable it:
   ```bash
   mv android/app/src/main/kotlin/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.kt \
      android/app/src/main/kotlin/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.kt.example
   ```
2. Rename the Java file to activate it:
   ```bash
   mv android/app/src/main/java/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.java.example \
      android/app/src/main/java/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.java
   ```
3. Run `flutter clean` and rebuild:
   ```bash
   flutter clean
   flutter run
   ```

---

## 2. Java vs. Kotlin Comparison

The Kotlin implementation is idiomatic, type-safe, and functionally equivalent to the Java codebase.

### 2.1. Class Constants
* **Java:** Declared as static member variables.
  ```java
  public static final String STREAM = "com.chamelalaboratory.demo.flutter_event_channel/eventChannel";
  ```
* **Kotlin:** Packaged inside a `companion object` block.
  ```kotlin
  companion object {
      const val STREAM = "com.chamelalaboratory.demo.flutter_event_channel/eventChannel"
  }
  ```

### 2.2. Runnable and Object Expressions
* **Java:** Uses anonymous inner classes.
  ```java
  private final Runnable runnable = new Runnable() {
      @Override
      public void run() { ... }
  };
  ```
* **Kotlin:** Uses object expressions.
  ```kotlin
  private val runnable = object : Runnable {
      override fun run() { ... }
  }
  ```

### 2.3. Event Payloads (Maps)
* **Java:** Utilizes Java collection library maps with explicit types.
  ```java
  java.util.Map<String, Object> event = new java.util.HashMap<>();
  event.put("type", "progress");
  ```
* **Kotlin:** Leverages idiomatic read-only map builders (`mapOf`).
  ```kotlin
  val event = mapOf(
      "type" to "progress",
      ...
  )
  ```

### 2.4. Null Safety and Cast Checks
* **Java:** Relies on manual runtime instance checks and type casting.
  ```java
  if (args instanceof Map) {
      Map<?, ?> map = (Map<?, ?>) args;
      Object val = map.get("totalCount");
  }
  ```
* **Kotlin:** Integrates compile-time null safety check expressions (`as?` smart cast and safe-call `?.let`).
  ```kotlin
  if (args is Map<*, *>) {
      (args["totalCount"] as? Number)?.let {
          totalCount = it.toInt()
      }
  }
  ```
