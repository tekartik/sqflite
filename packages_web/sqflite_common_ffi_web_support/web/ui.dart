import 'dart:async';
import 'dart:html' as html;

var lines = <String>[];
var countLineMax = 100;
var _output = html.querySelector('#output')!;
var _input = html.querySelector('#input')!;
void write(String message) {
  print(message);
  lines.add(message);
  if (lines.length > countLineMax + 10) {
    lines = lines.sublist(lines.length - countLineMax);
  }
  _output.text = lines.join('\n');
}

void addButton(String text, FutureOr<void> Function() action) {
  _input.append(html.ButtonElement()
    ..innerText = text
    ..onClick.listen((event) async {
      await action();
    }));
}
