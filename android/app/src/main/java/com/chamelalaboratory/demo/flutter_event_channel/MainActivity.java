package com.chamelalaboratory.demo.flutter_event_channel;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;

public class MainActivity extends FlutterActivity {

    // Single constant for the EventChannel name
    public static final String STREAM = "com.chamelalaboratory.demo.flutter_event_channel/eventChannel";
    private static final String TAG = "MainActivity";

    // Handler initialized with the main thread's Looper to ensure safe UI thread execution
    private final Handler handler = new Handler(Looper.getMainLooper());
    
    private EventChannel.EventSink attachEvent;
    private int count = 1;

    // Configurable stream arguments with default values
    private int updateIntervalMs = 200;
    private int totalCount = 100;

    // Runnable that simulates a continuous progress update stream
    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            // Safeguard to prevent sending events if the subscriber has cancelled
            if (attachEvent == null) {
                return;
            }

            if (count > totalCount) {
                // Signal completion to Flutter and stop scheduling
                attachEvent.endOfStream();
                stopEventStream();
                return;
            }

            double percentage = ((double) count / totalCount);
            Log.w(TAG, "Parsing From Native: " + percentage);
            
            // Construct structured event map for StandardMessageCodec
            java.util.Map<String, Object> event = new java.util.HashMap<>();
            event.put("type", "progress");
            event.put("current", count);
            event.put("total", totalCount);
            event.put("progress", percentage);
            event.put("timestamp", System.currentTimeMillis());

            // Send success event to the active Flutter listener
            attachEvent.success(event);
            
            count++;
            // Self-reschedule the next tick using the configured interval
            handler.postDelayed(this, updateIntervalMs);
        }
    };

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Modern and recommended way to register platform channels in configureFlutterEngine
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), STREAM).setStreamHandler(
                new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object args, final EventChannel.EventSink events) {
                        Log.w(TAG, "Adding listener");
                        stopEventStream();

                        // Reset config defaults
                        updateIntervalMs = 200;
                        totalCount = 100;

                        // Parse and validate arguments from Flutter
                        if (args instanceof Map) {
                            Map<?, ?> map = (Map<?, ?>) args;

                            // Validate updateIntervalMs (50ms to 10000ms)
                            Object intervalObj = map.get("updateIntervalMs");
                            if (intervalObj instanceof Number) {
                                int val = ((Number) intervalObj).intValue();
                                if (val < 50 || val > 10000) {
                                    events.error("INVALID_ARGUMENT", "updateIntervalMs must be between 50 and 10000 ms", val);
                                    return;
                                }
                                updateIntervalMs = val;
                            }

                            // Validate totalCount (1 to 1000)
                            Object countObj = map.get("totalCount");
                            if (countObj instanceof Number) {
                                int val = ((Number) countObj).intValue();
                                if (val < 1 || val > 1000) {
                                    events.error("INVALID_ARGUMENT", "totalCount must be between 1 and 1000", val);
                                    return;
                                }
                                totalCount = val;
                            }
                        }

                        attachEvent = events;
                        count = 1;
                        handler.post(runnable);
                    }

                    @Override
                    public void onCancel(Object args) {
                        Log.w(TAG, "Cancelling listener");
                        // Clean up callbacks and sink reference when Flutter cancels subscription
                        stopEventStream();
                    }
                }
        );
    }

    // Helper method to safely stop the runnable and clear references
    private void stopEventStream() {
        handler.removeCallbacks(runnable);
        attachEvent = null;
    }

    @Override
    protected void onDestroy() {
        // Ensure everything is cleanly terminated when the Activity is destroyed to avoid memory leaks
        stopEventStream();
        super.onDestroy();
    }
}
