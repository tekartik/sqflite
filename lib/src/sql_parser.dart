bool isWhitespace(int codeUnit) {
  switch (codeUnit) {
    case 9: // \t
    case 10: // \r
    case 13: // \n
    case 32: // space
      return true;
  }
  return false;
}

bool isStringWrapper(int codeUnit) {
  switch (codeUnit) {
    case 39: // '
    case 34: // "
    case 96: // `
      return true;
  }
  return false;
}

String unescapeText(String name) {
  if (name.length > 0) {
    var startCodeUnit = name.codeUnitAt(0);
    if (isStringWrapper(startCodeUnit)) {
      if (name.length > 1) {
        var endCodeUnit = name.codeUnitAt(name.length - 1);
        if (endCodeUnit == startCodeUnit) {
          return name.substring(1, name.length - 1);
        } else {
          return name.substring(1);
        }
      }
    }
  }
  return name;
}

class SqlParserIndex {
  int position;
}
class SqlParser {
  final String sql;
  int position = 0;

  SqlParser(this.sql);

  void skipWhitespaces({bool skip, SqlParserIndex index}) {
    int position = index?.position ?? this.position;
    while (true) {
      int codeUnit = sql.codeUnitAt(position);
      if (isWhitespace(codeUnit)) {
        position++;
      } else {
        break;
      }
    }
    if (skip == true) {
      this.position = position;
    }
    if (index != null) {
      index.position = position;
    }
  }

  bool atEnd([int position]) {
    return (position ?? this.position) == sql.length;
}
  String getNextToken({bool skip, SqlParserIndex index}) {
    index ??= SqlParserIndex()..position = this.position;
    skipWhitespaces(skip: skip, index: index);
    if (!atEnd(index.position)) {
      var sb = StringBuffer();

      int codeUnit = sql.codeUnitAt(index.position);
      int startCodeUnit;
      if (isStringWrapper(codeUnit)) {
        startCodeUnit = codeUnit;
      }
      sb.writeCharCode(codeUnit);
      index.position++;
      while (true) {
        if (atEnd(index.position)) {
          if (startCodeUnit != null) {
            return null;
          } else {
            break;
          }
        }
        codeUnit = sql.codeUnitAt(index.position);
        if (startCodeUnit != null) {
          sb.writeCharCode(codeUnit);
          if (codeUnit == startCodeUnit) {
            break;
          }
        } else {
          if (isWhitespace(codeUnit)) {
            break;
          } else {
            sb.writeCharCode(codeUnit);
          }
        }
        index.position++;
      }
      if (skip == true) {
        this.position = index.position;
      }
      return sb.toString();
    } else {
      return null;
    }

  }
  bool parseToken(String token) {
    var index = SqlParserIndex()..position = position;
    var nextToken = getNextToken(index: index);
    if (token.toLowerCase() == nextToken?.toLowerCase()) {
      // skip it
      position = index.position;
      return true;
    }
    return false;
  }
  bool parseTokens(List<String> tokens) {
    var index = SqlParserIndex()..position = position;
    for (var token in tokens) {
      var nextToken = getNextToken(index: index);
      if (token.toLowerCase() != nextToken?.toLowerCase()) {
        return false;
      }
    }
    // skip them
    position = index.position;
    return true;
  }
}