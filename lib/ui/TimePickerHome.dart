import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_duration_picker/flutter_duration_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './HistoryScreen.dart';
import './TimerScreen.dart';

var pageOpacity = 0.0;

class TimePicker extends StatefulWidget {
  @override
  TimePickerState createState() => TimePickerState();
}

class TimePickerState extends State<TimePicker> with TickerProviderStateMixin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  AnimationController controller;
  Duration timerValue = Duration(hours: 0, minutes: 1, seconds: 0);
  Duration timerPausedValue;
  Timer timer;
  Timer initialOpacityTimer;
  bool timerIsOn = false;
  bool timerIsPaused = true;
  List lastTimers = [];

  String get timeLeft {
    Duration duration = timerValue * controller.value;
    return '${duration.inHours}:${duration.inMinutes % 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  TimePickerState() {
    initialOpacityTimer = new Timer(const Duration(milliseconds: 0), () {
      setState(() {
        pageOpacity = 1;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: timerValue,
    );
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  void dispose() {
    super.dispose();
    initialOpacityTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Timer', style: TextStyle(color: Colors.black)),
          centerTitle: true,
        ),
        body: AnimatedOpacity(
          opacity: pageOpacity,
          duration: Duration(milliseconds: 1250),
          curve: Curves.easeIn,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Align(
                    alignment: FractionalOffset.center,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: showTimerInput(),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Builder(builder: (BuildContext context) {
                        return new FloatingActionButton(
                          heroTag: 'playButton',
                          child: AnimatedBuilder(
                            animation: controller,
                            builder: (BuildContext context, Widget child) {
                              return Icon(Icons.play_arrow);
                            },
                          ),
                          onPressed: () {
                            if (timerValue.inHours == 0 &&
                                timerValue.inMinutes == 0 &&
                                timerValue.inSeconds == 0) {
                              showSnackBar(context, 'Timer must not be null');
                            } else {
                              startTimer();
                            }
                          },
                        );
                      }),
                      FloatingActionButton(
                          heroTag: 'resetButton',
                          tooltip: 'Show history',
                          child: Icon(Icons.history),
                          onPressed: () => goToHistoryScreen(context))
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }

  showTimerInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Hero(
            tag: 'showTimer',
            child: DurationPicker(
              width: 450,
              duration: timerValue,
              snapToMins: 1,
              onChange: (val) {
                this.setState(() => timerValue = val);
                setState(() {
                  controller = AnimationController(
                    vsync: this,
                    duration: timerValue,
                  );
                });
              },
            ))
      ],
    );
  }

  startTimer() {
    lastTimers.add(timerValue.toString().split('.')[0]);
    Navigator.of(context)
        .push(new MaterialPageRoute<Map>(builder: (BuildContext context) {
      return new TimerCountDown(timerValue: timerValue);
    }));
  }

  showSnackBar(context, String text) {
    Scaffold.of(context).showSnackBar(new SnackBar(
      backgroundColor: Colors.blueGrey,
      duration: Duration(milliseconds: 1500),
      content: new Text(
        text,
        textAlign: TextAlign.center,
      ),
    ));
  }

  Future goToHistoryScreen(BuildContext context) async {
    Map results = await Navigator.of(context).push(new MaterialPageRoute<Map>(builder: (BuildContext context) {
      return new HistoryScreen(
          lastTimers: lastTimers.length > 10
              ? lastTimers.reversed.toList().sublist(0, 10)
              : lastTimers.reversed.toList());
    }));

    if (results != null && results.containsKey('timer')) {
      setState(() {
        timerValue = results['timer'];
        controller = AnimationController(
          vsync: this,
          duration: timerValue,
        );
      });
      startTimer();
    }
  }
}