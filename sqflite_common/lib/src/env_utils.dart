// environment utils

bool? _isRelease;

// http://stackoverflow.com/questions/29592826/detect-during-runtime-whether-the-application-is-in-release-mode-or-not

/// Check whether in release mode
bool get isRelease {
  if (_isRelease == null) {
    _isRelease = true;
    assert(() {
      _isRelease = false;
      return true;
    }());
  }
  return _isRelease!;
}

/// Check whether running in debug mode
bool get isDebug => !isRelease;

/// True when running on the web (compiled with dart2js or dart2wasm).
///
/// Same detection as flutter `kIsWeb`. The `identical(1, 1.0)` trick must not
/// be used here: it only detects JavaScript and is false with dart2wasm.
const bool kSqfliteIsWeb = bool.fromEnvironment('dart.library.js_interop');
