package com.chamelalaboratory.demo.flutter_event_channel;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

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

    // Runnable that simulates a continuous progress update stream
    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            // Safeguard to prevent sending events if the subscriber has cancelled
            if (attachEvent == null) {
                return;
            }

            int TOTAL_COUNT = 100;
            if (count > TOTAL_COUNT) {
                // Signal completion to Flutter and stop scheduling
                attachEvent.endOfStream();
                stopEventStream();
                return;
            }

            double percentage = ((double) count / TOTAL_COUNT);
            Log.w(TAG, "Parsing From Native: " + percentage);
            
            // Send success event to the active Flutter listener
            attachEvent.success(percentage);
            
            count++;
            // Self-reschedule the next tick every 200 milliseconds
            handler.postDelayed(this, 200);
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
                        // Reset stream state and start posting progress events
                        stopEventStream();
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
