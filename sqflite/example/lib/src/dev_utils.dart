export 'dart:async';

/// Deprecated to prevent keeping the code used.
@deprecated
void devPrint(Object object) {
  print(object);
}

/// Deprecated to prevent keeping the code used.
///
/// Can be use as a todo for weird code. int value = devWarning(myFunction());
/// The function is always called
@deprecated
T devWarning<T>(T value) => value;
