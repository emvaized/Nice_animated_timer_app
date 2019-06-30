import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final List lastTimers;

  HistoryScreen({Key key, this.lastTimers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('History'),
          centerTitle: true,
        ),
        body: lastTimers.isEmpty
            ? Center(
                child: Text(
                'No history yet',
                style: TextStyle(fontSize: 21, color: Colors.black87),
              ))
            : Hero(
                tag: 'resetButton',
                child: Scrollbar(
                    child: ListView.builder(
                  itemCount: lastTimers.length,
                  itemBuilder: (_, int position) {
                    return Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Card(
                          color: Colors.white,
                          elevation: 6,
                          child: ListTile(
                              title: Padding(
                                  padding: EdgeInsets.only(top: 15, bottom: 5),
                                  child: Text(
                                    lastTimers[position],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 25),
                                  )),
                              subtitle: Text(
                                  position == 0 ? '(last timer)' : '',
                                  textAlign: TextAlign.center),
                              trailing: Icon(Icons.restore),
                              leading: Container(width: 30),
                              onTap: () {
                                Navigator.pop(context, {
                                  'timer': Duration(
                                      hours: int.parse(lastTimers[position]
                                          .toString()
                                          .split(':')[0]),
                                      minutes: int.parse(lastTimers[position]
                                          .toString()
                                          .split(':')[1]),
                                      seconds: int.parse(lastTimers[position]
                                          .toString()
                                          .split(':')[2]))
                                });
                              }),
                        ));
                  },
                ))));
  }
}
