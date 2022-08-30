# Flutter Event Channel Demo
Get Stream Data through Native (Java) to Flutter Using Event Channel.

# Demo 
https://user-images.githubusercontent.com/53204654/187360492-b18380ef-8518-474c-81c1-2c2942903406.mp4

# Brief Code Explanation

# Native (Java) - Parser

A named channel for communicating with platform plugins using event streams.

Stream setup requests are encoded into binary before being sent, and binary events and errors received are decoded into Dart values. The MethodCodec used must be compatible with the one used by the platform plugin. This can be achieved by creating an EventChannel counterpart of this channel on the platform side. The Dart type of events sent and received is dynamic, but only values supported by the specified MethodCodec can be used.

The logical identity of the channel is given by its name. Identically named channels will interfere with each other's communication.

See: flutter.dev/platform-channels/


````

public static final String STREAM = "com.chamelalaboratory.demo.flutter_event_channel/eventChannel";
private EventChannel.EventSink attachEvent;

````

Create a Runnable thread that will increment the count value every 200 milliseconds. Max iteration is 100.
The increment count value will be divided by the max number, every 200 milliseconds because we need values for LinearProgressIndicator.

````
private int count = 1;
private Handler handler;

    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            int TOTAL_COUNT = 100;
            if (count > TOTAL_COUNT) {
                attachEvent.endOfStream(); // ends the stream
            } else {
            
                // we need to values for LinearProgressIndicator
                double percentage = ((double) count / TOTAL_COUNT);
                attachEvent.success(percentage);
                
                Log.w(TAG_NAME, "\nParsing From Native:  " + percentage);
            }
            count++;
            handler.postDelayed(this, 200);
        }
    };
````

It was much easy than I expected to add a new platform channel to stream data from native code. Simply implement the StreamHandler interface and emit events.


````
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
````

# Flutter - Receiver

Dart comes with built-in support for streams, and the EventChannel makes advantage of this support to tell native code when to start emitting events and when to stop. Simply listen to the platform channel stream to start the event emitter from the native side. Simply cancel the subscription when you're done.

````
 static const stream = EventChannel('com.chamelalaboratory.demo.flutter_event_channel/eventChannel');

  late StreamSubscription _streamSubscription;
  double _currentValue = 0.0;

  void _startListener() {
    _streamSubscription = stream.receiveBroadcastStream().listen(_listenStream);
  }

  void _cancelListener() {
    _streamSubscription.cancel();
    setState(() {
      _currentValue = 0;
    });
  }

  void _listenStream(value) {
    debugPrint("Received From Native:  $value\n");
    setState(() {
      _currentValue = value;
    });
  }
````

# Full Code (Java)

````
package com.chamelalaboratory.demo.flutter_event_channel;

import android.os.Bundle;
import android.os.Handler;

import java.util.Objects;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.EventChannel;


public class MainActivity extends FlutterActivity {

    public static final String STREAM = "com.chamelalaboratory.demo.flutter_event_channel/eventChannel";
    private EventChannel.EventSink attachEvent;
    final String TAG_NAME = "From_Native";
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
````

# Full Code (Flutter)

````
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const stream = EventChannel('com.chamelalaboratory.demo.flutter_event_channel/eventChannel');

  late StreamSubscription _streamSubscription;
  double _currentValue = 0.0;

  void _startListener() {
    _streamSubscription = stream.receiveBroadcastStream().listen(_listenStream);
  }

  void _cancelListener() {
    _streamSubscription.cancel();
    setState(() {
      _currentValue = 0;
    });
  }

  void _listenStream(value) {
    debugPrint("Received From Native:  $value\n");
    setState(() {
      _currentValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //Progress bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                value: _currentValue,
                backgroundColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(
              height: 5,
            ),

            // Value in text
            Text("Received Stream From Native:  $_currentValue".toUpperCase(),
                textAlign: TextAlign.justify),
            const SizedBox(
              height: 50,
            ),

            //Start Btn
            TextButton(
              onPressed: () => _startListener(),
              child: Text("Start Counter".toUpperCase()),
            ),
            const SizedBox(
              height: 50,
            ),

            //Cancel Btn
            TextButton(
              onPressed: () => _cancelListener(),
              child: Text("Cancel Counter".toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}
````

[LICENSE: MIT](LICENSE)
