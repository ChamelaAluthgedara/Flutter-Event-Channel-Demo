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
