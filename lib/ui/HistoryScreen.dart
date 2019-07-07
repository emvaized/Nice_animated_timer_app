import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  List lastTimers;

  HistoryScreen({Key key, this.lastTimers}) : super(key: key);

  @override
  _HistoryScreen2State createState() => _HistoryScreen2State();
}

class _HistoryScreen2State extends State<HistoryScreen> with TickerProviderStateMixin{
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {'newLastTimersList': widget.lastTimers});
        return false;
      },
      child: Hero(
        transitionOnUserGestures: true,
        tag: 'resetButton',
        child: new Scaffold(
            appBar: new AppBar(
              title: new Text('History'),
              centerTitle: true,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.clear_all),
                  tooltip: 'Clear all',
                  onPressed: () {
                    setState(() {
                      widget.lastTimers = [];
                    });
                  },
                )
              ],
            ),
            body: widget.lastTimers.length == 0
                ? Center(
                    child: FadeTransition(
                      opacity:  Tween<double>(begin: 0.0, end: 1.0).chain(
                        CurveTween(
                          curve: Curves.easeIn,
                        ),
                      ).animate(AnimationController(
                        vsync: this,
                        duration: Duration(milliseconds: 200),
                      )..forward()),
                      child: FittedBox(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.format_list_bulleted,
                            size: 45,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            'No history yet',
                            style: TextStyle(fontSize: 21, color: Colors.black87),
                          ),
                        ],
                  ),
                      ),
                    ))
                : Scrollbar(
                    child: AnimatedList(
                        initialItemCount: widget.lastTimers.length,
                        itemBuilder: (_, int position, animation) {
                          return FadeTransition(
                            opacity:
                                animation.drive(Tween(begin: 0.0, end: 1.0)),
                            child: Dismissible(
                                key: UniqueKey(),
                                onDismissed: (direction) {
                                  widget.lastTimers.removeAt(position);
                                  setState(() {});
                                  AnimatedList.of(_).removeItem(
                                      position, (context, animation) => Card());
                                },
                                child: position == 0
                                    ? buildFirstCard(position, context)
                                    : buildCard(position, context)),
                          );
                        }))),
      ),
    );
  }

  buildCard(int position, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        color: Colors.white,
        elevation: 6,
        child: ListTile(
            title: Padding(
                padding: EdgeInsets.all(5),
                child: Text(
                  widget.lastTimers[position],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25),
                )),
            trailing: Icon(Icons.restore),
            leading: Container(width: 30),
            onTap: () {
              Navigator.pop(context, {
                'timer': Duration(
                    hours: int.parse(
                        widget.lastTimers[position].toString().split(':')[0]),
                    minutes: int.parse(
                        widget.lastTimers[position].toString().split(':')[1]),
                    seconds: int.parse(
                        widget.lastTimers[position].toString().split(':')[2]))
              });
            }),
      ),
    );
  }

  buildFirstCard(int position, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        color: Colors.white,
        elevation: 6,
        child: ListTile(
            title: Padding(
                padding: EdgeInsets.only(bottom: 1, top: 5),
                child: Text(
                  widget.lastTimers[position],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25),
                )),
            subtitle: Text(
              '(last timer)',
              textAlign: TextAlign.center,
            ),
            trailing: Icon(Icons.restore),
            leading: Container(width: 30),
            onTap: () {
              Navigator.pop(context, {
                'timer': Duration(
                    hours: int.parse(
                        widget.lastTimers[position].toString().split(':')[0]),
                    minutes: int.parse(
                        widget.lastTimers[position].toString().split(':')[1]),
                    seconds: int.parse(
                        widget.lastTimers[position].toString().split(':')[2]))
              });
            }),
      ),
    );
  }
}
