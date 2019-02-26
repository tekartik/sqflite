import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../model/main_item.dart';

class MainItemWidget extends StatefulWidget {
  MainItemWidget(this.item, this.onTap);

  final MainItem item;
  final Function onTap; // = Function(MainItem item);

  @override
  _MainItemWidgetState createState() => _MainItemWidgetState();
}

class _MainItemWidgetState extends State<MainItemWidget> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(widget.item.title),
        subtitle: Text(widget.item.description),
        onTap: _onTap);
  }

  void _onTap() {
    widget.onTap(widget.item);

    //print(widget.item.route);
    //Navigator.pushNamed(context, widget.item.route);
  }
}
