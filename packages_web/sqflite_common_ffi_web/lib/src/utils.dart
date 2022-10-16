// TODO optimize
/// Fix web result to send through MessagePort
Object? dataToEncodable(Object? data) {
  // Basic type ok
  if (data is String || data is bool || data is num || data == null) {
    return data;
  }
  if (data is Map) {
    data = data.map((key, value) => MapEntry(key, dataToEncodable(value)));
  } else if (data is List) {
    data = data.map((value) => dataToEncodable(value)).toList();
  } else if (data is BigInt) {
    data = {'@bigInt': data.toString()};
  } else {
    throw UnsupportedError(
        'dataToEncodable: invalid type for $data ${data.runtimeType}');
  }
  return data;
}

/// Decrypt web result from encodable.
Object? dataFromEncodable(Object? data) {
  // Basic type ok
  if (data is String || data is bool || data is num || data == null) {
    return data;
  }
  if (data is Map) {
    var bigIntEncoded = data['@@bigint'];
    if (bigIntEncoded is String && data.length == 1) {
      return BigInt.tryParse(bigIntEncoded);
    }
    data = data.map((key, value) => MapEntry(key, dataFromEncodable(value)));
  } else if (data is List) {
    data = data.map((value) => dataFromEncodable(value)).toList();
  } else {
    throw UnsupportedError(
        'dataFromEncodate: invalid type for $data ${data.runtimeType}');
  }
  return data;
}
