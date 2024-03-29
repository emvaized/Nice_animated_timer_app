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
  BuildContext scaffoldContext;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  AnimationController controller;
  Animation animation;
  Duration timerValue = Duration(hours: 0, minutes: 1, seconds: 0),
      timerPausedValue;
  Timer timer, initialOpacityTimer;
  bool timerIsOn = false, timerIsPaused = true;
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
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    animation = Tween(begin: 0.0, end: 1.0)
        .chain(new CurveTween(
          curve: Curves.easeInOut,
        ))
        .animate(controller);
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    super.initState();
  }

  @override
  void dispose() {
    initialOpacityTimer.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.timer, color: Colors.black87),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Timer App', style: TextStyle(color: Colors.black87)),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton:  Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ScaleTransition(
                scale: animation,
                child: new FloatingActionButton(
                  heroTag: 'playButton',
                  child: Icon(Icons.play_arrow),
                  onPressed: () {
                    if (timerValue.inHours == 0 &&
                        timerValue.inMinutes == 0 &&
                        timerValue.inSeconds == 0) {
                      showSnackBar('Timer must not be null');
                    } else {
                      startTimer();
                    }
                  },
                ),
              ),
              ScaleTransition(
                scale: animation,
                child: FloatingActionButton(
                    heroTag: 'resetButton',
                    tooltip: 'Show history',
                    child: Icon(Icons.history),
                    onPressed: () => goToHistoryScreen(context)),
              )
            ],
          ),
        ),
        body: Builder(builder: (BuildContext context) {
          scaffoldContext = context;
          controller.forward();
          return ScaleTransition(
            scale: animation,
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
                ],
              ),
            ),
          );
        }));
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

  startTimer() async {
    lastTimers.add(timerValue.toString().split('.')[0]);
//    Map results = await Navigator.of(context)
//        .push(new MaterialPageRoute<Map>(builder: (BuildContext context) {
//      return new TimerCountDown(timerValue: timerValue);
//    }));
//
//    if (results != null && results.containsKey('timerCancelled'))
//      Future.delayed(Duration(milliseconds: 350)).then((context) {
//        showSnackBar('Timer cancelled');
//      });
    Navigator.of(context)
        .push(new MaterialPageRoute<Map>(builder: (BuildContext context) {
      return new TimerCountDown(timerValue: timerValue);
    }));
  }

  showSnackBar(String text) {
    Scaffold.of(scaffoldContext).showSnackBar(new SnackBar(
      backgroundColor: Colors.blueGrey,
      duration: Duration(milliseconds: 1350),
      content: new Text(
        text,
        textAlign: TextAlign.center,
      ),
    ));
  }

  Future goToHistoryScreen(BuildContext context) async {
    Map results = await Navigator.of(context)
        .push(new MaterialPageRoute<Map>(builder: (BuildContext context) {
      return new HistoryScreen(lastTimers: lastTimers.reversed.toList());
    }));

    if (results != null) {
      if (results.containsKey('timer')) {
        setState(() {
          timerValue = results['timer'];
          controller = AnimationController(
            vsync: this,
            duration: timerValue,
          );
        });
        startTimer();
      }

      if (results.containsKey('newLastTimersList')) {
        lastTimers = results['newLastTimersList'];
      }
    }
  }
}
