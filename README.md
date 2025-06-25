# SQLiteConnection Dart Library

SQLiteConnection provides a streamlined interface for interacting with SQLite databases in Dart, supporting various operations like search, insert, update, delete, and more.

## Features

- **Search Operations**: Case-insensitive, column-specific, multi-column search.
- **Insert Operations**: Single and batch insertions.
- **Update Operations**: Single and batch updates with conflict handling.
- **Delete Operations**: Single and batch deletions.
- **Advanced Queries**: Group by, pagination, and random row retrieval.
- **Database Management**: Table creation, dropping, and backups.

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  sqlite_flutter_pcl: ^0.0.50
```

## Basic Usage

### Initialization

```dart

import 'package:sqlite_flutter_pcl/sqlite_connection.dart';

# Create table class implements ISQLiteItem

```dart
class SqlModel implements ISQLiteItem {
  static const String tableName = 'sql_model';
  static const String tableId = 'id';
  static const String tableTitle = 'title';
  static const String tableValue = 'value';


  int? id;
  String? title;
  String? value;

  SqlModel({this.id, this.title, this.value});

  @override
  String getTableName() {
    return tableName;
  }

  @override
  int getPrimaryKey() {
    return id ?? 0;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      tableId: id,
      tableTitle: title,
      tableValue: value,
    };
  }

  @override
  String getPrimaryKeyName() {
    return tableId;
  }

  @override
  ISQLiteItem fromMap(Map<String, dynamic> map) {
    return SqlModel(
      id: map[tableId],
      title: map[tableTitle],
      value: map[tableValue],
    );
  }
}

```

# Create instance of SQLiteConnection

```dart
   //Init if SQLiteConnection not initialize when new instance created
    SQLiteConnection.initDatabaseLib();
    //Sqlite filepath
    final databasePath = await getTemporaryDatabaseFilePath();
    final connection = SQLiteConnection(path: databasePath);
    //create table
    connection.createTable(SqlModel());
    //insert new item;
    var newItem = SqlModel(title: 'Title 1', value: 'Value 1');
    await connection.insert(newItem);
    //retrieve items
    var isqliteItems = await connection.toList(SqlModel());
    //convert to type list
    var items = isqliteItems.whereType<SqlModel>().toList();
    var items = isqliteItems.cast<SqlModel>().toList();
    //update items
    for (var item in items) {
      item.value = 'Updated';
      await connection.update(item);
    }
    //OR
    await connection.updateAll(items);
    //delete items
    await connection.deleteAll(items);
    //query single value
    var queryItems = await connection.toListWhere(SqlModel(), 'title', 'Title 1');
    //query items by value
    var queryItems = await connection.searchColumns(SqlModel(), 'title', 'Title 1');

    // Returns a list of items with titles 'title1' and 'title2', using a batch query for efficiency.
    var results = await connection.toListWhereValuesAre(SqlModel(), 'title', ['title1', 'title2']);
    
    //Search across multiple columns. 
    var columnNames = ['word', 'number', 'lemma', 'xlit', 'pronounce', 'description'];
    var items = await db.toListColumns(Strongs(), columnNames, query);

    //Delete all table records
    connection.deleteRecords(SqlModel());
    //Drop table
    connection.dropTable(SqlModel());



    Future<String> getTemporaryDatabaseFilePath() async {
    final directory = await getTemporaryDirectory();
    final path = join(directory.path, 'your_database.db');
    print(path);
    return path;
  }
```

### Item

```
var sqlItem = SqlModel(title: 'Title 1', value: 'Value 1');
```
#### Single Item
```dart
final id = await connection.insert(sqlItem);
```

#### Multiple Items
```dart
final totalInserted = await connection.insertAll(sqlItems);
```

### Update Data

#### Single Item
```dart
await connection.update(sqlItem);
```

#### Multiple Items
```dart
final totalUpdated = await connection.updateAll(sqlItems);
```

### Delete Data

#### Single Item
```dart
final rowsDeleted = await connection.delete(sqlItem);
```

#### Multiple Items
```dart
final totalDeleted = await connection.deleteAll(sqlItems);
```

### Search Data

#### Single Column Search
```dart
final results = await connection.search(sqlItem, 'columnName', 'searchQuery');
```

#### Multiple Column Search
```dart
final results = await connection.searchColumns(
  sqlItem,
  ['column1', 'column2'],
  'searchQuery',
);
```

#### Exact Match
```dart
final result = await connection.whereColumnHasValue(sqlItem, 'columnName', value);
```

### Query Data

#### Get All Rows
```dart
final items = await connection.toList(sqlItem);
```

#### Filtered Rows
```dart
final items = await connection.toListWhereColumnHasValue(sqlItem, 'columnName', value);
```

#### Paginated Rows
```dart
final items = await connection.paginate(sqlItem, limit: 10, offset: 20);
```

#### Grouped Rows
```dart
final items = await connection.groupBy(
  sqlItem,
  ['column1', 'column2'],
  'groupByColumn',
  orderByColumn: 'orderByColumn',
);
```

### Utility Functions

- **Backup Database**
  ```dart
  await connection.backupDatabase('/path/to/backup.db');
  ```

- **Drop Table**
  ```dart
  await connection.dropTable(sqlItem);
  ```

- **Vacuum Database**
  ```dart
  await connection.vacuum(sqlItem);
  ```

- **Count Rows**
  ```dart
  final count = await connection.count(sqlItem);
  ```

- **Retrieve Table Columns**
  ```dart
  final columns = await connection.tableColumns('tableName');
  ```

---

[https://pub.dev/packages/sqlite_flutter_pcl](https://pub.dev/packages/sqlite_flutter_pcl)
