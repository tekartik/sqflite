/// Encrypt web result to encodable (to send query from web app or response from worker)
Object? dataToEncodable(Object? data) => _dataToEncodable(data);

/// Decrypt web result from encodable.
Object? dataFromEncodable(Object? data) => _dataFromEncodable(data);

/// True for null, num, String, bool
bool _isBasicTypeOrNull(dynamic value) {
  if (value == null) {
    return true;
  } else if (value is num || value is String || value is bool) {
    return true;
  }
  return false;
}

abstract class _TypeAdapter<T> {
  final String tag;

  _TypeAdapter(this.tag);

  /// True if the value is the proper type.
  bool isType(Object value) {
    return value is T;
  }

  T asType(Object value) => value as T;

  T? decode(Object value);
  Object? encode(T value);
  Object? encodeAny(Object value) => encode(asType(value));
}

class _BigIntAdapter extends _TypeAdapter<BigInt> {
  _BigIntAdapter() : super('BigInt');

  @override
  BigInt? decode(Object value) {
    if (value is String) {
      return BigInt.tryParse(value);
    }
    throw UnsupportedError('invalid encoding for bigInt $value');
  }

  @override
  Object? encode(BigInt value) => value.toString();
}

var _adapters = [_BigIntAdapter()];
var _adaptersByTag =
    _adapters.asMap().map((key, value) => MapEntry(value.tag, value));

// Look like custom?
bool _looksLikeCustomType(Map map) {
  if (map.length == 1) {
    var key = map.keys.first;
    if (key is String) {
      return key.startsWith('@');
    }
    throw ArgumentError.value(key);
  }
  return false;
}

Object? _dataToEncodable(Object? valueOrNull) {
  if (_isBasicTypeOrNull(valueOrNull)) {
    return valueOrNull;
  }
  var value = valueOrNull!;
  // handle adapters
  for (var adapter in _adapters) {
    if (adapter.isType(value)) {
      return {'@${adapter.tag}': adapter.encodeAny(value)};
    }
  }

  if (value is Map) {
    var map = value;
    if (_looksLikeCustomType(map)) {
      return <String, Object?>{'@': map};
    }
    Map<String, Object?>? clone;
    map.forEach((key, item) {
      if (key is! String) {
        throw ArgumentError.value(key);
      }
      var converted = _dataToEncodable(item);
      if (!identical(converted, item)) {
        clone ??= Map<String, Object?>.from(map);
        clone![key] = converted;
      }
    });
    return clone ?? map;
  } else if (value is List) {
    var list = value;
    List? clone;
    for (var i = 0; i < list.length; i++) {
      var item = list[i];
      var converted = _dataToEncodable(item);
      if (!identical(converted, item)) {
        clone ??= List.from(list);
        clone[i] = converted;
      }
    }
    return clone ?? list;
  } else {
    throw UnsupportedError(
        'Unsupported value type ${value.runtimeType} for $value');
  }
}

Object? _dataFromEncodable(Object? valueOrNull) {
  if (_isBasicTypeOrNull(valueOrNull)) {
    return valueOrNull;
  }
  var value = valueOrNull!;
  if (value is Map) {
    var map = value;
    if (_looksLikeCustomType(map)) {
      var tag = (map.keys.first as String).substring(1);
      if (tag == '') {
        return map.values.first as Object;
      }
      var adapter = _adaptersByTag[tag];
      if (adapter != null) {
        var encodedValue = value.values.first as Object?;
        if (encodedValue == null) {
          return null;
        }
        try {
          return adapter.decode(encodedValue) as Object;
        } catch (e) {
          print('$e - ignoring $encodedValue ${encodedValue.runtimeType}');
        }
      }
    }

    Map<String, Object?>? clone;
    map.forEach((key, item) {
      var converted = _dataFromEncodable(item as Object?);
      if (!identical(converted, item)) {
        clone ??= Map<String, Object?>.from(map);
        clone![key.toString()] = converted;
      }
    });
    return clone ?? map;
  } else if (value is List) {
    var list = value;
    List? clone;
    for (var i = 0; i < list.length; i++) {
      var item = list[i];
      var converted = _dataFromEncodable(item as Object?);
      if (!identical(converted, item)) {
        clone ??= List.from(list);
        clone[i] = converted;
      }
    }
    return clone ?? list;
  } else {
    throw UnsupportedError(
        'Unsupported value type ${value.runtimeType} for $value');
  }
}
