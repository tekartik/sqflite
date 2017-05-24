import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite_example/model/item.dart';

class ItemWidget extends StatefulWidget {
  Item item;
  ItemWidget(this.item);
  @override
  _ItemWidgetState createState() => new _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (widget.item.state) {
      case ItemState.running:
        icon = Icons.more_horiz;
        break;
      case ItemState.success:
        icon = Icons.check;
        color = Colors.green;
        break;
      case ItemState.failure:
        icon = Icons.close;
        color = Colors.red;
        break;
    }
    return new ListTile(
        leading: new IconButton(
          icon: new Icon(icon, color: color),

          onPressed: null, // null disables the button
        ),
        title: new Text(widget.item.name));
  }
}
