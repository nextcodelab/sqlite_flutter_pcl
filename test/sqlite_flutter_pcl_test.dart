import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_flutter_pcl/sqlite_flutter_pcl.dart';
//flutter pub publish --dry-run
//flutter pub publish

void main() async {
  test('adds one to input values', () {
    //expect(calculator.addOne(0), 1);
    expect(Tester().testInsert, 1);
  });
}

class Tester {
  String _status = "insert";
  final List<SqlModel> sampleDataInsert = [
    SqlModel(id: 0, title: 'Title 0', value: 'Value 0'),
    SqlModel(id: 0, title: 'Title 1', value: 'Value 1'),
    SqlModel(id: 0, title: 'Title 2', value: 'Value 2'),
    SqlModel(id: 0, title: 'Title 3', value: 'Value 3'),
    // Add more instances here without specifying the ID
  ];

  // Iterate through the list and insert each instance into the database

  void testInsert() async {
    SQLiteConnection.initDatabaseLib();
    final databasePath = await getTemporaryDatabasePath();
    final connection = SQLiteConnection(path: databasePath);
    if (_status == "insert") {
      await connection.deleteRecords(SqlModel());
      for (final item in sampleDataInsert) {
        await insertIntoDatabase(item);
      }
      _status = 'update';
    } else if (_status == 'update') {
      var sampleDataUpdate = await connection.toList(SqlModel());
      for (final item in sampleDataUpdate) {
        (item as SqlModel).value = 'updated';
        await insertIntoDatabase(item, insert: false);
      }
      _status = 'insert';
    }
  }

  Future<String> getTemporaryDatabasePath() async {
    final directory = await getTemporaryDirectory();
    final path = join(directory.path, 'your_database.db');
    print(path);
    return path;
  }

  Future<void> insertIntoDatabase(SqlModel item, {bool insert = true}) async {
    final databasePath = await getTemporaryDatabasePath();
    final connection = SQLiteConnection(path: databasePath);
    await connection.createTable(item);
    if (insert) {
      await connection.insert(item);
    } else {
      await connection.update(item);
    }
  }

  void testVoid() async {
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
    //search items
    var searchItems = await connection.search(SqlModel(), 'title', 'title 1');
    //query with multiple columns
    Map<String, dynamic> columnNameAndValues = {
      'title': 'Title 1',
      'value': 'Value 2',
    };
    var results = await connection.whereOr(SqlModel(), columnNameAndValues);

    //Delete all table records
    connection.deleteRecords(SqlModel());
    //Delete table
    connection.deleteTable(SqlModel());
  }
}

class SqlModel implements ISQLiteItem {
  int? id;
  String? title;
  String? value;

  SqlModel({this.id, this.title, this.value});

  @override
  String getTableName() {
    return 'sql_model';
  }

  @override
  int getPrimaryKey() {
    return id ?? 0;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'value': value,
    };
  }

  @override
  String getPrimaryKeyName() {
    return 'id';
  }

  @override
  ISQLiteItem fromMap(Map<String, dynamic> map) {
    return SqlModel(
      id: map['id'],
      title: map['title'],
      value: map['value'],
    );
  }
}
