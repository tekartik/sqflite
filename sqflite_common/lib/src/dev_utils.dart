/// Deprecated to prevent keeping the code used.
@Deprecated('Dev only')
void devPrint(Object? object) {
  // ignore: avoid_print
  print(object);
}

/// Deprecated to prevent keeping the code used.
///
/// Can be use as a todo for weird code. int value = devWarning(myFunction());
/// The function is always called
@Deprecated('Dev only')
T devWarning<T>(T value) => value;
