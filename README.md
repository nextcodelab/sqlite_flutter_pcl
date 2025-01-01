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
    var queryItems = await connection.where(SqlModel(), 'title', 'Title 1');
    //query items by value
    var queryItems = await connection.serchByColumn(SqlModel(), 'title', 'Title 1');

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

[https://pub.dev/packages/sqlite_flutter_pcl](https://pub.dev/packages/sqlite_flutter_pcl)
