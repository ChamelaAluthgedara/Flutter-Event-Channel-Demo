package com.chamelalaboratory.demo.flutter_event_channel;

import android.os.Bundle;
import android.os.Handler;

import java.util.Objects;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.EventChannel;


public class MainActivity extends FlutterActivity {

    public static final String STREAM = "com.chamelalaboratory.demo.flutter_event_channel/eventChannel";
    final String TAG_NAME = "From_Native";

    private EventChannel.EventSink attachEvent;
    private int count = 1;
    private Handler handler;

    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            int TOTAL_COUNT = 100;
            if (count > TOTAL_COUNT) {
                attachEvent.endOfStream();
            } else {
                double percentage = ((double) count / TOTAL_COUNT);
                Log.w(TAG_NAME, "\nParsing From Native:  " + percentage);
                attachEvent.success(percentage);
            }
            count++;
            handler.postDelayed(this, 200);
        }
    };


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        new EventChannel(Objects.requireNonNull(getFlutterEngine()).getDartExecutor(), STREAM).setStreamHandler(
                new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object args, final EventChannel.EventSink events) {
                        Log.w(TAG_NAME, "Adding listener");
                        attachEvent = events;
                        count = 1;
                        handler = new Handler();
                        runnable.run();
                    }

                    @Override
                    public void onCancel(Object args) {
                        Log.w(TAG_NAME, "Cancelling listener");
                        handler.removeCallbacks(runnable);
                        handler = null;
                        count = 1;
                        attachEvent = null;
                        System.out.println("StreamHandler - onCanceled: ");
                    }
                }
        );
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        handler.removeCallbacks(runnable);
        handler = null;
        attachEvent = null;
    }
}
