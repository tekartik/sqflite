@JS()
library tekartik_js_utils.src.js_utils.js_interop;

import 'package:js/js.dart';

/// Visible Object keys for a map
@JS('Object.keys')
external List<String> jsObjectKeys(Object obj);
