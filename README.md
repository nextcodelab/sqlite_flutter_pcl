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
    final databasePath = await getTemporaryDatabasePath();
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
    var queryItems = await connection.whereSingle(SqlModel(), 'title', 'Title 1');
    //query items by value
    var queryItems = await connection.where(SqlModel(), 'title', 'Title 1');
    //search items
    var searchItems = await connection.search(SqlModel(), 'title', 'title 1');
    //search by multiple columns with single query
    var results = await connection.whereSearchOr(SqlModel(), ['title', 'value'], query);
    
    // Returns a list of items with titles 'title1' and 'title2', using a batch query for efficiency.
    var results = await connection.toListWhereValuesAre(SqlModel(), 'title', ['title1', 'title2']);

    //Delete all table records
    connection.deleteRecords(SqlModel());
    //Delete table
    connection.deleteTable(SqlModel());
```

[pub.dev](https://pub.dev/packages/sqlite_flutter_pcl)
