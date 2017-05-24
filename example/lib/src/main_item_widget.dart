import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite_example/model/item.dart';
import 'package:sqflite_example/model/main_item.dart';

class MainItemWidget extends StatefulWidget {
  MainItem item;
  Function onTap; // = Function(MainItem item);
  MainItemWidget(this.item, this.onTap);
  @override
  _MainItemWidgetState createState() => new _MainItemWidgetState();
}

class _MainItemWidgetState extends State<MainItemWidget> {
  @override
  Widget build(BuildContext context) {
    return new ListTile(
        title: new Text(widget.item.title),
        subtitle: new Text(widget.item.description),
        onTap: _onTap);
  }

  void _onTap() {
    widget.onTap(widget.item);

    //print(widget.item.route);
    //Navigator.pushNamed(context, widget.item.route);
  }
}
