# Supported types

The API offers a way to save a record as map of type `Map<String, Object?>`. This map cannot be an
arbitrary map:
- Keys are column in a table (declared when creating the table)
- Values are field values in the record of type `num`, `String` or `Uint8List`

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

Another solution is to encoded nested maps and lists as json (or other format), declaring the column
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

No validity check is done on values yet so please avoid non supported types [https://www.sqlite.org/datatype3.html](https://www.sqlite.org/datatype3.html)

`DateTime` is not a supported SQLite type. Personally I store them as 
int (millisSinceEpoch) or string (iso8601). SQLite `TIMESTAMP` type sometimes requires using [date functions](https://www.sqlite.org/lang_datefunc.html). 
`TIMESTAMP` values are read as `String` that the application needs to parse.

`bool` is not a supported SQLite type. Use `INTEGER` and 0 and 1 values.

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

* SQLite typ: `BLOB`
* Dart type: `Uint8List`
