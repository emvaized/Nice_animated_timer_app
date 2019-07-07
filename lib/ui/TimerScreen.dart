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
  AnimationController controller, playButtonController;
  bool timerIsPaused = false;
  bool timerIsOn = true;
  Timer timer;
  Duration timerPausedValue;
  BuildContext scaffoldContext;

  Animation resetButtonAnimation;

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
    playButtonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
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
    return WillPopScope(
        onWillPop: () async =>
            timerIsOn ? await showWarningOnTimerRunning() : true,
        child: Scaffold(
            appBar: AppBar(
              title: Text('Timer'),
            ),
            body: Builder(builder: (BuildContext context) {
              scaffoldContext = context;
              return buildPage();
            })));
  }

  Widget buildPage() {
    return Scaffold(
      floatingActionButton: timerIsPaused
          ? Padding(
              padding: const EdgeInsets.all(50.0),
              child: FloatingActionButton(
                  isExtended: true,
                  child: timerIsOn ? Icon(Icons.replay) : Icon(Icons.arrow_back),
                  heroTag: 'resetButton',
                  tooltip: timerIsOn ? 'Reset timer' : 'Go back',
                  onPressed: resetTimer))
          : null,
      body: Padding(
          padding: EdgeInsets.only(
            left: 15.0,
            right: 15.0,
            top: 60.0,
            bottom: 15.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                  child: Align(
                      alignment: FractionalOffset.center,
                      child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Hero(
                            tag: 'showTimer',
                            flightShuttleBuilder: (
                              BuildContext flightContext,
                              Animation<double> animation,
                              HeroFlightDirection flightDirection,
                              BuildContext fromHeroContext,
                              BuildContext toHeroContext,
                            ) {
                              final Hero toHero = toHeroContext.widget;

                              if (flightDirection == HeroFlightDirection.push) {
                                return ScaleTransition(
                                  scale: animation.drive(
                                    Tween<double>(begin: 0.5, end: 1.0).chain(
                                      CurveTween(
                                        curve: Curves.easeIn,
                                      ),
                                    ),
                                  ),
                                  child: toHero.child,
                                );
                              } else if (flightDirection ==
                                  HeroFlightDirection.pop) {
                                return ScaleTransition(
                                  scale: animation.drive(
                                    Tween<double>(begin: 1.0, end: 1.0).chain(
                                      CurveTween(
                                        curve: Curves.easeIn,
                                      ),
                                    ),
                                  ),
                                  child: toHero.child,
                                );
                              }
                            },
                            child: Material(
                              child: InkWell(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(200)),
                                  onTap: () {
                                    if (timerIsPaused) {
                                      timer = startTimer();
                                    } else {
                                      pauseTimer();
                                    }
                                  },
                                  child: Stack(
                                    children: <Widget>[
                                      new ProgressAnimatedCircle(
                                          controller: controller,
                                          timerIsPaused: timerIsPaused),
                                      new TimerCountText(
                                          timerValue: widget.timerValue,
                                          controller: controller,
                                          timerIsPaused: timerIsPaused,
                                          timerIsOn: timerIsOn),
                                    ],
                                  )),
                            ),
                          )))),
              Container(
                margin: EdgeInsets.all(50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Builder(builder: (BuildContext context) {
                      return new FloatingActionButton(
                        heroTag: 'playButton',
                        child: AnimatedIcon(
                                icon: AnimatedIcons.pause_play,
                                progress: playButtonController),
                        onPressed: () {
                          if (controller.isAnimating) {
                            pauseTimer();
                          } else {
                            timer = startTimer();
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  startTimer() {
    if (timerPausedValue == null)
      Future.delayed(Duration(milliseconds: 150)).then((context) {
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
    playButtonController.reverse();
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
    playButtonController.forward();
  }

  resetTimer() {
    if (timerIsOn) {
      print('timer reset');
      timer.cancel();
      setState(() {
        timerIsOn = false;
        timerPausedValue = null;
        timerIsPaused = true;
      });
      showSnackBar('Timer was reset', 1250);
      controller.animateTo(1,
          duration: Duration(milliseconds: 150), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  showSnackBar(String text, milliseconds) {
    Scaffold.of(scaffoldContext).showSnackBar(new SnackBar(
      backgroundColor: timerIsOn ? Colors.blue : Colors.blueGrey,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              title: Text(
                'Timer run out !',
                textAlign: TextAlign.center,
              ),
              content: Icon(Icons.timer, size: 100, color: Colors.blueGrey),
              actions: <Widget>[
                new FlatButton(
                    onPressed: () => {
                          controller.value = 1,
                          setState(() {
                            timerIsOn = false;
                            timerPausedValue = null;
                            timerIsPaused = true;
                          }),
                          Navigator.of(context).pop(),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0))),
                  title: Row(
                    children: <Widget>[
                      Icon(Icons.error_outline),
                      SizedBox(width: 30),
                      Text(
                        'Timer is running!',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  content: Text(
                    'Do you want to stop it?',
                  ),
                  actions: <Widget>[
                    new FlatButton(
                        onPressed: () => {
                              answer = false,
                              Navigator.of(context).pop(),
                              Navigator.of(context).pop(),
                             //  Navigator.pop(context, {'timerCancelled': 1})
                            },
                        child: new Text('Okay')),
                    new FlatButton(
                        onPressed: () =>
                            {answer = false, Navigator.of(context).pop()},
                        child: new Text('Cancel'))
                  ],
                )))
        .then((value) => answer);
  }
}

class ProgressAnimatedCircle extends StatelessWidget {
  const ProgressAnimatedCircle({
    Key key,
    @required this.controller,
    @required this.timerIsPaused,
  }) : super(key: key);

  final AnimationController controller;
  final bool timerIsPaused;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget child) {
        return CustomPaint(
            painter: TimerPainter(
          animation: controller,
          backgroundColor: Colors.grey,
          color: timerIsPaused ? Colors.black45 : Colors.blue,
        ));
      },
    ));
  }
}

class TimerCountText extends StatelessWidget {
  const TimerCountText({
    Key key,
    @required this.controller,
    @required this.timerIsPaused,
    @required this.timerIsOn,
    @required this.timerValue,
  }) : super(key: key);

  final AnimationController controller;
  final bool timerIsPaused;
  final bool timerIsOn;
  final timerValue;

  String get timeLeft {
    Duration duration = timerValue * controller.value;
    return '${duration.inHours}:${duration.inMinutes % 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: FractionalOffset.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          AnimatedBuilder(
              animation: controller,
              builder: (BuildContext context, Widget child) {
                return Column(
                  children: <Widget>[
                    Text(timeLeft,
                        style: TextStyle(
                            fontSize: 90,
                            color: Colors.black54,
                            fontWeight: FontWeight.w300)),
                    !timerIsPaused
                        ? Text('Timer is running',
                            style:
                                TextStyle(color: Colors.blue, fontSize: 18.0))
                        : timerIsOn
                            ? Text('PAUSED',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 18.0))
                            : Text('STOPPED',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 18.0)),
                  ],
                );
              }),
        ],
      ),
    );
  }
}
