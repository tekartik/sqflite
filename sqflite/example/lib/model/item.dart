enum ItemState { running, success, failure }

class Item {
  Item(this.name);

  ItemState state = ItemState.running;
  String name;
}
