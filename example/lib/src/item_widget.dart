import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../model/item.dart';

class ItemWidget extends StatefulWidget {
  ItemWidget(this.item, this.onTap);

  final Item item;
  final Function onTap; // = Function(MainItem item);

  @override
  _ItemWidgetState createState() => _ItemWidgetState();
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
    return ListTile(
        leading: IconButton(
          icon: Icon(icon, color: color),

          onPressed: null, // null disables the button
        ),
        title: Text(widget.item.name),
        onTap: _onTap);
  }

  void _onTap() {
    widget.onTap(widget.item);

    //print(widget.item.route);
    //Navigator.pushNamed(context, widget.item.route);
  }
}
