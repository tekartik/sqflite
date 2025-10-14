import 'package:sqflite_example_common/src/common_import.dart';

/// Item states.
enum ItemState {
  /// test not run yet.
  none,

  /// test is running.
  running,

  /// test succeeded.
  success,

  /// test fails.
  failure,

  /// test warning
  warning, // when false is returned
}

/// Menu item.
class Item {
  /// Menu item.
  Item(this.name);

  /// Menu item state.
  ItemState state = ItemState.running;

  /// Menu item name/
  String name;
}

/// Menu item implementation.
class SqfMenuItem extends Item {
  /// Menu item implementation.
  SqfMenuItem(super.name, this.body, {this.summary}) {
    state = ItemState.none;
  }

  /// Summary.
  String? summary;

  /// Run the item.
  Future run() {
    state = ItemState.running;
    return Future<void>.delayed(const Duration()).then((_) async {
      try {
        var result = await body();
        if (result == false) {
          state = ItemState.warning;
        } else {
          state = ItemState.success;
        }
      } catch (e) {
        state = ItemState.failure;
        rethrow;
      }
    });
  }

  /// Menu item body.
  final FutureOr<dynamic> Function() body;
}
