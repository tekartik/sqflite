import 'package:sqflite_example/src/common_import.dart';

enum ItemState { none, running, success, failure }

class Item {
  Item(this.name);

  ItemState state = ItemState.running;
  String name;
}

class MenuItem extends Item {
  MenuItem(String name, this.body, {this.summary}) : super(name) {
    state = ItemState.none;
  }

  String summary;

  Future run() {
    state = ItemState.running;
    return Future.delayed(Duration()).then((_) async {
      try {
        await body();
        state = ItemState.success;
      } catch (e) {
        state = ItemState.failure;
        rethrow;
      }
    });
  }

  final FutureOr Function() body;
}
