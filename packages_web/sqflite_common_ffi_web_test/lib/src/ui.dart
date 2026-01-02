import 'dart:async';
import 'package:web/web.dart' as web;

var lines = <String>[];
var countLineMax = 100;
var _output = web.document.querySelector('#output')!;
var _input = web.document.querySelector('#input')!;
void write(String message) {
  print(message);
  lines.add(message);
  if (lines.length > countLineMax + 10) {
    lines = lines.sublist(lines.length - countLineMax);
  }
  _output.textContent = lines.join('\n');
}

void addButton(String text, FutureOr<void> Function() action) {
  _input.append(
    (web.document.createElement('button') as web.HTMLButtonElement)
      ..innerText = text
      ..onClick.listen((event) async {
        await action();
      }),
  );
}
