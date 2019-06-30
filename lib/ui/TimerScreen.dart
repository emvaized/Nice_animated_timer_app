import 'dart:async';
import 'package:flutter/material.dart';
import './utils/ProgressBarDrawer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimerCountDown extends StatefulWidget {
  final Duration timerValue;

  TimerCountDown({Key key, this.timerValue}) : super(key: key);

  @override
  _TimerCountDownState createState() => _TimerCountDownState();
}

class _TimerCountDownState extends State<TimerCountDown>
    with TickerProviderStateMixin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  AnimationController controller;
  bool timerIsPaused = false;
  bool timerIsOn = true;
  Timer timer;
  Duration timerPausedValue;
  BuildContext scaffoldContext;

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    controller = AnimationController(
      vsync: this,
      duration: widget.timerValue,
    );
    timer = startTimer();
  }

  @override
  void dispose() {
    print('timer cancelled');
    timer.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return WillPopScope(
        onWillPop: () async =>
            timerIsOn ? await showWarningOnTimerRunning() : true,
        child: Scaffold(
            appBar: AppBar(),
            body: Builder(builder: (BuildContext context) {
              scaffoldContext = context;
              return Stack(
                children: <Widget>[
                  Hero(
                      transitionOnUserGestures: true,
                      tag: 'showTimer',
                      child: Container()),
                  Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Column(
                        children: <Widget>[
                          Expanded(
                              child: Align(
                                  alignment: FractionalOffset.center,
                                  child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: GestureDetector(
                                          onTap: () {
                                            if (timerIsPaused) {
                                              timer = startTimer();
                                            } else {
                                              pauseTimer();
                                            }
                                          },
                                          child: Stack(
                                            children: <Widget>[
                                              Positioned.fill(
                                                child: AnimatedBuilder(
                                                  animation: controller,
                                                  builder:
                                                      (BuildContext context,
                                                          Widget child) {
                                                    return CustomPaint(
                                                        painter: TimerPainter(
                                                      animation: controller,
                                                      backgroundColor:
                                                          Colors.grey,
                                                      color: timerIsPaused
                                                          ? Colors.black45
                                                          : Colors.blue,
                                                    ));
                                                  },
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    FractionalOffset.center,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: <Widget>[
                                                    AnimatedBuilder(
                                                        animation: controller,
                                                        builder: (BuildContext
                                                                context,
                                                            Widget child) {
                                                          return Column(
                                                            children: <Widget>[
                                                              Text(
                                                                timeLeft,
                                                                style: themeData
                                                                    .textTheme
                                                                    .display4,
                                                              ),
                                                              !timerIsPaused
                                                                  ? Text(
                                                                      'Timer is running',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blue,
                                                                          fontSize:
                                                                              18.0))
                                                                  : timerIsOn
                                                                      ? Text(
                                                                          'PAUSED',
                                                                          style: TextStyle(
                                                                              color: Colors
                                                                                  .grey,
                                                                              fontSize:
                                                                                  18.0))
                                                                      : Text(
                                                                          'STOPPED',
                                                                          style: TextStyle(
                                                                              color: Colors.grey,
                                                                              fontSize: 18.0)),
                                                            ],
                                                          );
                                                        }),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ))))),
                          Container(
                            margin: EdgeInsets.all(50.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                new Builder(builder: (BuildContext context) {
                                  return new FloatingActionButton(
                                    heroTag: 'playButton',
                                    child: AnimatedBuilder(
                                      animation: controller,
                                      builder:
                                          (BuildContext context, Widget child) {
                                        return Icon(!timerIsPaused
                                            ? Icons.pause
                                            : Icons.play_arrow);
                                      },
                                    ),
                                    onPressed: () {
                                      if (controller.isAnimating) {
                                        pauseTimer();
                                      } else {
                                        timer = startTimer();
                                      }
                                    },
                                  );
                                }),
                                timerIsPaused
                                    ? FloatingActionButton(
                                        child: timerIsOn
                                            ? Icon(Icons.replay)
                                            : Icon(Icons.arrow_back),
                                        heroTag: 'resetButton',
                                        tooltip: 'Reset timer',
                                        onPressed: resetTimer)
                                    : Container()
                              ],
                            ),
                          ),
                        ],
                      )),
                ],
              );
            })));
  }

  String get timeLeft {
    Duration duration = widget.timerValue * controller.value;
    return '${duration.inHours}:${duration.inMinutes % 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  startTimer() {
    if (timerPausedValue == null)
      Future.delayed(Duration(milliseconds: 50)).then((context) {
        showSnackBar(
            widget.timerValue.inHours != 0
                ? 'Timer set for ${widget.timerValue.inHours} hours, ${widget.timerValue.inMinutes % 60} minutes'
                : 'Timer set for ${widget.timerValue.inMinutes % 60} minutes',
            2000);
      });
    controller.reverse(from: controller.value == 0.0 ? 1.0 : controller.value);
    timerPausedValue != null
        ? print(
            'timer on for ${timerPausedValue.inHours}h, ${timerPausedValue.inMinutes % 60}m, ${timerPausedValue.inSeconds % 60} s')
        : print(
            'timer on for ${widget.timerValue.inHours}h, ${widget.timerValue.inMinutes % 60}m, ${widget.timerValue.inSeconds % 60} s');
    setState(() {
      timerIsPaused = false;
      timerIsOn = true;
    });
    return timerPausedValue != null
        ? new Timer(timerPausedValue, () => {showAlertOnFinish()})
        : new Timer(widget.timerValue, () => {showAlertOnFinish()});
  }

  pauseTimer() {
    controller.stop();
    print('timer paused');
    setState(() {
      timerIsPaused = true;
      timerPausedValue = controller.duration * controller.value;
    });
    timer.cancel();
  }

  resetTimer() {
    if (timerIsOn) {
      print('timer reset');
      showSnackBar('Timer was reset', 1250);
      timer.cancel();
      controller.value = 1;
      setState(() {
        timerIsOn = false;
        timerPausedValue = null;
        timerIsPaused = true;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  showSnackBar(String text, milliseconds) {
    Scaffold.of(scaffoldContext).showSnackBar(new SnackBar(
      backgroundColor: Colors.blue,
      duration: Duration(milliseconds: milliseconds),
      content: new Text(
        text,
        textAlign: TextAlign.center,
      ),
    ));
  }

  showAlertOnFinish() {
    print('timer run out!');
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: ((_) => AlertDialog(
              title: new Text(
                'Timer run out !',
                textAlign: TextAlign.center,
              ),
              content: new Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.timer, size: 100, color: Colors.blueGrey)
                ],
              ),
              actions: <Widget>[
                new FlatButton(
                    onPressed: () => {
                          controller.value = 1,
                          setState(() {
                            timerIsOn = false;
                            timerPausedValue = null;
                            timerIsPaused = true;
                          }),
                          Navigator.of(context).pop()
                        },
                    child: new Text('Okay')),
              ],
            )));
    showNotificationOnFinish();
  }

  Future showNotificationOnFinish() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Timer run out!',
      widget.timerValue.inHours != 0
          ? '${widget.timerValue.inHours} hours and ${widget.timerValue.inMinutes} minutes have passed'
          : '${widget.timerValue.inMinutes} minutes have passed',
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  showWarningOnTimerRunning() async {
    bool answer;
    return await showDialog(
            context: context,
            barrierDismissible: false,
            builder: ((_) => AlertDialog(
                  title: Text(
                    'Timer is running',
                    textAlign: TextAlign.center,
                  ),
                  content: Text(
                    'Do you want to stop it?',
                  ),
                  actions: <Widget>[
                    new FlatButton(
                        onPressed: () =>
                            {answer = true, Navigator.of(context).pop()},
                        child: new Text('Yes')),
                    new FlatButton(
                        onPressed: () =>
                            {answer = false, Navigator.of(context).pop()},
                        child: new Text('Cancel'))
                  ],
                )))
        .then((value) => answer);
  }
}
