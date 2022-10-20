# sqflite_web dev info

To develop, simply run the example that has a custom shared worker implementation

In chrome View log in:

chrome://inspect/#workers

To override the shared worker file name, in pubspec.yaml:

```yaml
sqflite:
  # Update for force changing file name for shared worker
  # to force an app update until a better solution is found
  # default being sqflite_sw.js
  #
  # Could be sqflite_sw_v1.js, sqflite_sw_v2.js,...
  #
  # Re run setup then and change the sharedWorkerUri options in the client.
  #
  sqflite_common_ffi_web:
    sw_js_file: sqflite_sw_v1.js
```