import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/src/sql_parser.dart';

void main() {
  group("sql_parser", () {
    test("isWhitespace", () {
      var whitespaces = '\t\n\r ';
      for (int codeUnit in whitespaces.codeUnits) {
        expect(isWhitespace(codeUnit), isTrue, reason: 'codeUnit: $codeUnit');
      }
      var noWhitespaces = 'ab10';
      for (int codeUnit in noWhitespaces.codeUnits) {
        expect(isWhitespace(codeUnit), isFalse);
      }
    });

    test("isStringWrapper", () {
      var stringWrapper = '\'"`';
      for (int codeUnit in stringWrapper.codeUnits) {
        expect(isStringWrapper(codeUnit), isTrue, reason: 'codeUnit: $codeUnit');
      }
      var noStringWrapper = 'ab10 ';
      for (int codeUnit in noStringWrapper.codeUnits) {
        expect(isStringWrapper(codeUnit), isFalse);
      }
    });

    test("unescapeText", () {
      expect(unescapeText('table'), 'table');
      expect(unescapeText('"table"'), 'table');
      expect(unescapeText('"table'), 'table');
      expect(unescapeText('"table`'), 'table`');
      expect(unescapeText('`table`'), 'table');
      expect(unescapeText('\'table\''), 'table');

    });

    test('getNextToken', () {
      var parser = SqlParser('test');
      expect(parser.getNextToken(),'test');

      parser = SqlParser(' test');
      expect(parser.getNextToken(),'test');


      parser = SqlParser('test 2');
      expect(parser.getNextToken(skip: true),'test');
      expect(parser.getNextToken(skip: true),'2');
      expect(parser.atEnd(), isTrue);

      var index = SqlParserIndex();
      parser = SqlParser('test 2');
      expect(parser.getNextToken(index: index),'test');
      expect(index.position, 4);
      expect(parser.getNextToken(index: index),'2');
      expect(index.position, 6);
    });

    test('parseTokens', () {
      var parser = SqlParser('test');
      expect(parser.parseTokens(['TeSt']), isTrue);
      parser = SqlParser('test 2');
      expect(parser.parseTokens(['test', '2']), isTrue);
    });
  });
}
