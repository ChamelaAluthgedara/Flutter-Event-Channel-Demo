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

    // Single constant for the EventChannel names
    public static final String STREAM = "com.chamelalaboratory.demo.flutter_event_channel/eventChannel";
    public static final String BATTERY_STREAM = "com.chamelalaboratory.demo.flutter_event_channel/batteryChannel";
    private static final String TAG = "MainActivity";

    // Handler initialized with the main thread's Looper to ensure safe UI thread execution
    private final Handler handler = new Handler(Looper.getMainLooper());
    
    private EventChannel.EventSink attachEvent;
    private ProgressGenerator progressGenerator;

    // Runnable that simulates a continuous progress update stream using ProgressGenerator state
    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            // Safeguard to prevent sending events if the subscriber has cancelled
            if (attachEvent == null || progressGenerator == null) {
                return;
            }

            // Simulate a native failure if configured and count reaches 50
            if (progressGenerator.shouldSimulateErrorNow()) {
                java.util.Map<String, Object> errorDetails = new java.util.HashMap<>();
                errorDetails.put("current", progressGenerator.getCount());
                errorDetails.put("total", progressGenerator.getTotalCount());
                errorDetails.put("timestamp", System.currentTimeMillis());
                errorDetails.put("description", "Demonstration of a simulated native stream failure.");

                attachEvent.error("SIMULATED_ERROR", "Simulated native failure occurred.", errorDetails);
                stopEventStream();
                return;
            }

            if (progressGenerator.isComplete()) {
                // Signal completion to Flutter and stop scheduling
                attachEvent.endOfStream();
                stopEventStream();
                return;
            }

            double percentage = progressGenerator.getProgressPercentage();
            Log.w(TAG, "Parsing From Native: " + percentage);
            
            // Construct structured event map for StandardMessageCodec
            java.util.Map<String, Object> event = new java.util.HashMap<>();
            event.put("type", "progress");
            event.put("current", progressGenerator.getCount());
            event.put("total", progressGenerator.getTotalCount());
            event.put("progress", percentage);
            event.put("timestamp", System.currentTimeMillis());

            // Send success event to the active Flutter listener
            attachEvent.success(event);
            
            progressGenerator.increment();
            // Self-reschedule using the configured interval
            handler.postDelayed(this, progressGenerator.getUpdateIntervalMs());
        }
    };

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Register the progress EventChannel
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), STREAM).setStreamHandler(
                new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object args, final EventChannel.EventSink events) {
                        Log.w(TAG, "Adding listener");
                        stopEventStream();

                        int interval = 200;
                        int countVal = 100;
                        boolean simulateError = false;

                        // Parse arguments from Flutter
                        if (args instanceof Map) {
                            Map<?, ?> map = (Map<?, ?>) args;

                            // Parse shouldSimulateError argument
                            Object errorObj = map.get("shouldSimulateError");
                            if (errorObj instanceof Boolean) {
                                simulateError = (Boolean) errorObj;
                            }

                            // Parse updateIntervalMs (validated by ProgressGenerator)
                            Object intervalObj = map.get("updateIntervalMs");
                            if (intervalObj instanceof Number) {
                                interval = ((Number) intervalObj).intValue();
                            }

                            // Parse totalCount (validated by ProgressGenerator)
                            Object countObj = map.get("totalCount");
                            if (countObj instanceof Number) {
                                countVal = ((Number) countObj).intValue();
                            }
                        }

                        // Try instantiating progress generator, returning platform error if inputs are invalid
                        try {
                            progressGenerator = new ProgressGenerator(interval, countVal, simulateError);
                        } catch (IllegalArgumentException e) {
                            events.error("INVALID_ARGUMENT", e.getMessage(), null);
                            return;
                        }

                        attachEvent = events;
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

        // Register the battery status EventChannel
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), BATTERY_STREAM).setStreamHandler(
                new EventChannel.StreamHandler() {
                    private android.content.BroadcastReceiver batteryReceiver;

                    @Override
                    public void onListen(Object arguments, final EventChannel.EventSink events) {
                        Log.w(TAG, "Adding battery listener");
                        batteryReceiver = new android.content.BroadcastReceiver() {
                            @Override
                            public void onReceive(android.content.Context context, android.content.Intent intent) {
                                int status = intent.getIntExtra(android.os.BatteryManager.EXTRA_STATUS, -1);
                                boolean isCharging = status == android.os.BatteryManager.BATTERY_STATUS_CHARGING ||
                                                     status == android.os.BatteryManager.BATTERY_STATUS_FULL;
                                
                                int level = intent.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1);
                                int scale = intent.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, -1);
                                double batteryPct = (scale > 0) ? (level / (double) scale) : 0.0;

                                java.util.Map<String, Object> data = new java.util.HashMap<>();
                                data.put("level", batteryPct);
                                data.put("isCharging", isCharging);

                                events.success(data);
                            }
                        };
                        
                        registerReceiver(
                            batteryReceiver,
                            new android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED)
                        );
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        Log.w(TAG, "Cancelling battery listener");
                        if (batteryReceiver != null) {
                            unregisterReceiver(batteryReceiver);
                            batteryReceiver = null;
                        }
                    }
                }
        );
    }

    // Helper method to safely stop the runnable and clear references
    private void stopEventStream() {
        handler.removeCallbacks(runnable);
        attachEvent = null;
        progressGenerator = null;
    }

    @Override
    protected void onDestroy() {
        // Ensure everything is cleanly terminated when the Activity is destroyed to avoid memory leaks
        stopEventStream();
        super.onDestroy();
    }
}
