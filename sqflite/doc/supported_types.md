# Supported types

The API offers a way to save a record as map of type `Map<String, Object?>`. This map cannot be an
arbitrary map:
- Keys are column in a table (declared when creating the table)
- Values are field values in the record of type `int`, `num`, `String`, `Uint8List` or `null`

Nested content is not supported. For example, the following simple map is not supported:

```dart
{
  "title": "Table",
  "size": {"width": 80, "height": 80}
}
```

It should be flattened. One solution is to modify the map structure:

```sql
CREATE TABLE Product (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  width INTEGER,
  height INTEGER)
```

```dart
{"title": "Table", "width": 80, "height": 80}
```

Another solution is to encode nested maps and lists as json (or other format), declaring the column
as a String.


```sql
CREATE TABLE Product (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  size TEXT
)

```
```dart
{
  'title': 'Table',
  'size': '{"width":80,"height":80}'
};
```

## Supported SQLite types

Values must be `int`, `num`, `String`, `Uint8List` or `null`. See also the SQLite
[datatype documentation](https://www.sqlite.org/datatype3.html).

`DateTime` is not a supported SQLite type. Personally I store them as 
int (millisSinceEpoch) or string (iso8601). SQLite `TIMESTAMP` type sometimes requires using [date functions](https://www.sqlite.org/lang_datefunc.html). 
`TIMESTAMP` values are read as `String` that the application needs to parse.

`bool` is not a supported SQLite type. Use `INTEGER` and 0 and 1 values.

A blob must be a `Uint8List`. A `List<int>` is not a blob.

Other types are rejected: `sqflite_common_ffi` (desktop, tests) and
`sqflite_common_ffi_web` throw a `DatabaseException` (`Invalid sql argument
type`), the `sqflite` plugin prints a warning in debug mode and the result
depends on the platform. Convert the values yourself:

```dart
// Write: convert to SQLite types
await db.insert('Event', {
  'done': done ? 1 : 0,
  'date': date.millisecondsSinceEpoch, // or date.toIso8601String() in a TEXT column
  'data': Uint8List.fromList([1, 2, 3]), // not a List<int>
});

// Read: convert back
var row = (await db.query('Event')).first;
var readDone = row['done'] == 1;
var readDate = DateTime.fromMillisecondsSinceEpoch(row['date'] as int);
var readData = row['data'] as Uint8List;
```

### INTEGER

* SQLite type: `INTEGER`
* Dart type: `int`
* Supported values: from -2^63 to 2^63 - 1

### REAL

* SQLite type: `REAL`
* Dart type: `num`

### TEXT

* SQLite type: `TEXT`
* Dart type: `String`

### BLOB

* SQLite type: `BLOB`
* Dart type: `Uint8List`
