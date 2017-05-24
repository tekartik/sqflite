enum ItemState { running, success, failure }

class Item {
  ItemState state = ItemState.running;
  Item(this.name);
  String name;
}
