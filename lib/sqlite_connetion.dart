import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite_flutter_pcl/models/isqlite_item.dart';

class SQLiteConnection {
  ///The full sqlite file path
  final String path;

  SQLiteConnection({required this.path}) {
    _initLib();
  }
  void _initLib() {
    initDatabaseLib();
  }

  Future<Database> getOpenDatabase() async {
    var database = await openDatabase(path, version: 1);
    return database;
  }

  Future<List<ISQLiteItem>> toList(ISQLiteItem item) async {
    final db = await getOpenDatabase();
    final tableName = item.getTableName();
    final List<Map<String, dynamic>> results = await db.query(tableName);
    // Convert the query results into a list of ISQLiteItem objects
    final List<ISQLiteItem> items =
        results.map((map) => item.fromMap(map)).toList();
    return items;
  }

  /// Retrieves a list of items that match the exact condition for the specified column.
  /// This method does not account for case differences; it performs a case-sensitive match.
  ///
  /// Example usage:
  /// var results = await connection.toListWhere(yourItem, 'column_name', 'value_to_match');
  Future<List<ISQLiteItem>> toListWhere(
    ISQLiteItem item,
    String columnName,
    dynamic columnValueOf, // Allow any type (int, double, String, etc.)
  ) async {
    String condition = '$columnName = ?';
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    // Remove limit to fetch all results
    var maps = await db.query(
      item.getTableName(),
      where: condition,
      whereArgs: [
        columnValueOf
      ], // Pass the value as an array (can be int, double, or String)
    );

    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  Future<List<ISQLiteItem>> toListWhereColumns(
    ISQLiteItem item,
    Map<String, dynamic>
        columnValues, // Map of column names and their dynamic values
  ) async {
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    String tableName = item.getTableName();

    // Build the WHERE clause dynamically based on the provided column names
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    columnValues.forEach((columnName, value) {
      whereConditions.add('$columnName = ?');
      whereArgs.add(value);
    });

    String condition = whereConditions.join(' AND ');

    // Query the database
    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
    );

    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  Future<List<ISQLiteItem>> getRandomItems(ISQLiteItem item, int count) async {
    final db = await getOpenDatabase();
    final tableName = item.getTableName();

    // Query the table and order by random, limit by the given count
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT * FROM $tableName ORDER BY RANDOM() LIMIT ?',
      [count], // Use parameterized queries to avoid SQL injection
    );

    // Convert the query results into a list of ISQLiteItem objects
    final List<ISQLiteItem> items =
        results.map((map) => item.fromMap(map)).toList();

    return items;
  }

  Future<int> insert(ISQLiteItem item) async {
    var db = await getOpenDatabase();
    var map = item.toMap();
    if (map[item.getPrimaryKeyName()] is int &&
        map[item.getPrimaryKeyName()] == 0) {
      map[item.getPrimaryKeyName()] = null;
    }
    var row = await db.insert(item.getTableName(), map);
    return row;
  }

  Future<int> insertAllSlow(List<ISQLiteItem> items) async {
    var db = await getOpenDatabase();
    var totalRow = 0;
    for (var item in items) {
      var map = item.toMap();
      if (map[item.getPrimaryKeyName()] is int &&
          map[item.getPrimaryKeyName()] == 0) {
        map[item.getPrimaryKeyName()] = null;
      }
      await db.insert(item.getTableName(), map);
      totalRow++;
    }
    return totalRow;
  }

  Future<int> insertAll(List<ISQLiteItem> items) async {
    var db = await getOpenDatabase();
    int totalRow = 0;

    await db.transaction((txn) async {
      for (var item in items) {
        var map = item.toMap();
        // Ensure primary key is null for auto-increment
        if (map[item.getPrimaryKeyName()] is int &&
            map[item.getPrimaryKeyName()] == 0) {
          map[item.getPrimaryKeyName()] = null;
        }

        // Insert the record and capture the result
        var result = await txn.insert(item.getTableName(), map);
        var id = result;
        totalRow++;
      }
    });
    return totalRow;
  }

  Future<void> update(ISQLiteItem item) async {
    final db = await getOpenDatabase();
    final map = item.toMap();
    final id = map[item.getPrimaryKeyName()];

    if (id != null) {
      // Perform an update with the same ID
      await db.update(item.getTableName(), map,
          where: '${item.getPrimaryKeyName()} = ?', whereArgs: [id]);
    } else {
      // Handle the case where ID is null (e.g., insert as a new record or raise an error)
    }
  }

  Future<void> updateAll(List<ISQLiteItem> items) async {
    final db = await getOpenDatabase();
    for (var item in items) {
      final map = item.toMap();
      final id = map[item.getPrimaryKeyName()];

      if (id != null) {
        // Perform an update with the same ID
        await db.update(item.getTableName(), map,
            where: '${item.getPrimaryKeyName()} = ?', whereArgs: [id]);
      } else {
        // Handle the case where ID is null (e.g., insert as a new record or raise an error)
      }
    }
  }

  Future<int> delete(ISQLiteItem item) async {
    var db = await getOpenDatabase();
    final primaryKeyValue = item.toMap()[item.getPrimaryKeyName()];
    var rowsDeleted = 0;
    if (primaryKeyValue != null) {
      rowsDeleted = await db.delete(
        item.getTableName(),
        where: '${item.getPrimaryKeyName()} = ?',
        whereArgs: [primaryKeyValue],
      );
    } else {
      // Handle the case where the primary key is null (e.g., raise an error).
      // Return 0 to indicate that no rows were deleted.
    }
    return rowsDeleted;
  }

  Future<int> deleteAll(List<ISQLiteItem> items) async {
    var db = await getOpenDatabase();
    var totalDeleted = 0;
    for (var item in items) {
      final primaryKeyValue = item.toMap()[item.getPrimaryKeyName()];

      if (primaryKeyValue != null) {
        await db.delete(
          item.getTableName(),
          where: '${item.getPrimaryKeyName()} = ?',
          whereArgs: [primaryKeyValue],
        );
        totalDeleted++;
      } else {
        // Handle the case where the primary key is null (e.g., raise an error).
        // Return 0 to indicate that no rows were deleted.
      }
    }
    return totalDeleted;
  }

  Future<void> deleteTable(ISQLiteItem item) async {
    final database = await getOpenDatabase();
    await database.execute('DROP TABLE IF EXISTS ${item.getTableName()}');
    database.close();
  }

  Future<void> deleteRecords(ISQLiteItem item) async {
    final db = await getOpenDatabase();
    await db.rawDelete('DELETE FROM ${item.getTableName()}');
    // Reset the auto-increment primary key to 1
    await db.rawUpdate(
        'DELETE FROM sqlite_sequence WHERE name = ?', [item.getTableName()]);
  }

  Future<List<ISQLiteItem>> where(
      ISQLiteItem item, String columnName, dynamic columnValueOf,
      {int? limit}) async {
    String condition = '$columnName = ?';
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();
    var maps = await db.query(
      item.getTableName(),
      where: condition,
      whereArgs: [columnValueOf], // Pass the value as an array
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  Future<ISQLiteItem?> whereSingle(
    ISQLiteItem item,
    String columnName,
    dynamic columnValueOf,
  ) async {
    String condition = '$columnName = ?';
    var db = await getOpenDatabase();
    var maps = await db.query(
      item.getTableName(),
      where: condition,
      whereArgs: [columnValueOf], // Pass the value as an array
      limit: 1, // Set limit to 1 to return only a single item
    );

    if (maps.isNotEmpty) {
      return item.fromMap(maps.first); // Return the first matching item
    } else {
      return null; // Return null if no match found
    }
  }

  Future<ISQLiteItem?> whereSingleColumns(
    ISQLiteItem item,
    Map<String, dynamic> columnValues, // Map of column names and their values
  ) async {
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    // Build the WHERE clause dynamically based on the provided column names and values
    columnValues.forEach((columnName, value) {
      whereConditions.add('$columnName = ?');
      whereArgs.add(value);
    });

    // Join all conditions with "AND"
    String condition = whereConditions.join(' AND ');

    var db = await getOpenDatabase();
    var maps = await db.query(
      item.getTableName(),
      where: condition,
      whereArgs: whereArgs, // Pass the column values as an array
      limit: 1, // Set limit to 1 to return only a single item
    );

    if (maps.isNotEmpty) {
      return item.fromMap(maps.first); // Return the first matching item
    } else {
      return null; // Return null if no match is found
    }
  }

  /// Fetches multiple items from the database based on a specific column and a list of values.
  ///
  /// This function uses a batch query to efficiently retrieve multiple items.
  ///
  /// @param item The `ISQLiteItem` instance representing the type of items to fetch.
  /// @param columnName The name of the column to filter by.
  /// @param columnValueList A list of values to filter the query by.
  /// @return A list of `ISQLiteItem` objects that match the query criteria.
  Future<List<ISQLiteItem>> toListWhereValuesAre(
    ISQLiteItem item,
    String columnName,
    List<String> columnValueList,
  ) async {
    final db = await getOpenDatabase();
    final batch = db.batch();
    final resultList = <ISQLiteItem>[];
    try {
      // Add queries to the batch for each column value
      for (final columnValue in columnValueList) {
        batch.query(
          item.getTableName(),
          where: '$columnName = ?',
          whereArgs: [columnValue],
        );
      }

      // Commit batch and process results
      final rawResults = await batch.commit();

      // rawResults is a list of lists, where each sublist is the result of a query
      for (final queryResult in rawResults) {
        if (queryResult is List) {
          for (final result in queryResult) {
            final liteItem = item.fromMap(result);
            resultList.add(liteItem);
          }
        }
      }
      return resultList;
    } catch (error) {
      // Handle database error (log or rethrow)
      return [];
    }
  }

  Future<Batch> getBatch() async {
    final db = await getOpenDatabase();
    final batch = db.batch();
    return batch;
  }

  Future<List<ISQLiteItem>> whereAnd(
      ISQLiteItem item, Map<String, dynamic> columnNameAndValues,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    columnNameAndValues.forEach((columnName, columnValue) {
      whereConditions.add('$columnName = ?');
      whereArgs.add(columnValue);
    });

    String condition = whereConditions.join(' AND ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  Future<List<ISQLiteItem>> whereOr(
      ISQLiteItem item, Map<String, dynamic> columnNameAndValues,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    columnNameAndValues.forEach((columnName, columnValue) {
      whereConditions.add('$columnName = ?');
      whereArgs.add(columnValue);
    });

    String condition = whereConditions.join(' OR ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  /// Performs a case-sensitive search in multiple columns of an SQLite table with AND condition.
  ///
  /// This method searches for the specified values in the given [columnNameAndValues]
  /// of the [tableName] and returns a list of items that match all the search criteria.
  /// It uses the LIKE operator for searching.
  ///
  /// Parameters:
  /// - [item]: An instance of ISQLiteItem representing the database table schema.
  /// - [columnNameAndValues]: A map of column names and values to search for.
  ///
  /// Returns a list of ISQLiteItem objects that match all the search criteria.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<ISQLiteItem> searchResults = await whereSearchAnd(
  ///   MyDatabaseItem(), // Replace with your ISQLiteItem implementation
  ///   {
  ///     'title': 'flutter',
  ///     'category': 'mobile',
  ///   },
  /// );
  ///
  /// for (var result in searchResults) {
  ///   print(result.toString());
  /// }
  /// ```

  Future<List<ISQLiteItem>> whereSearchAnd(
      ISQLiteItem item, Map<String, dynamic> columnNameAndValues,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    columnNameAndValues.forEach((columnName, columnValue) {
      // Modify the condition to use LIKE for searching
      whereConditions.add('$columnName LIKE ?');
      // Modify the whereArgs to use '%' for wildcard search
      whereArgs.add('%$columnValue%');
    });

    String condition = whereConditions.join(' AND ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  /// Performs a search in multiple columns of an SQLite table with exact matching (no "LIKE" operator)
  /// and an "AND" condition.
  ///
  /// This method searches for the specified exact values in the given [columnNameAndValues] of the
  /// [tableName] and returns a list of items that match all the search criteria.
  ///
  /// Parameters:
  /// - [item]: An instance of ISQLiteItem representing the database table schema.
  /// - [columnNameAndValues]: A map of column names and exact values to search for.
  ///
  /// Returns a list of ISQLiteItem objects that match all the search criteria.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<ISQLiteItem> searchResults = await whereSearchExactAnd(
  ///   MyDatabaseItem(), // Replace with your ISQLiteItem implementation
  ///   {
  ///     'title': 'Flutter',
  ///     'category': 'Mobile',
  ///   },
  /// );
  ///
  /// for (var result in searchResults) {
  ///   print(result.toString());
  /// }
  /// ```

  Future<List<ISQLiteItem>> whereSearchExactAnd(
      ISQLiteItem item, Map<String, dynamic> columnNameAndValues,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    columnNameAndValues.forEach((columnName, columnValue) {
      // Modify the condition to use = for exact matching
      whereConditions.add('$columnName = ?');
      whereArgs.add(columnValue);
    });

    String condition = whereConditions.join(' AND ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  /// Performs a case-insensitive search in multiple columns of an SQLite table.
  ///
  /// This method searches for the specified query in the given [columnNames] of the
  /// [tableName] and returns a list of items that match the search criteria. It uses
  /// the LIKE operator for searching and COLLATE NOCASE for case-insensitivity.
  ///
  /// Parameters:
  /// - [item]: An instance of ISQLiteItem representing the database table schema.
  /// - [columnNames]: A list of column names to search in.
  /// - [query]: The search query to match against the specified columns.
  ///
  /// Returns a list of ISQLiteItem objects that match the search criteria.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<ISQLiteItem> searchResults = await whereSearchOr(
  ///   MyDatabaseItem(), // Replace with your ISQLiteItem implementation
  ///   ['title', 'description', 'author'],
  ///   'flutter',
  /// );
  ///
  /// for (var result in searchResults) {
  ///   print(result.toString());
  /// }
  /// ```

  Future<List<ISQLiteItem>> whereSearchOr(
      ISQLiteItem item, List<String> columnNames, String query,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    // Modify the condition to use LIKE for searching and COLLATE NOCASE for case-insensitivity
    for (var columnName in columnNames) {
      whereConditions.add('$columnName LIKE ? COLLATE NOCASE');
      whereArgs.add('%$query%');
    }

    String condition = whereConditions.join(' OR ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  /// Performs a case-insensitive search in a specified column of an SQLite table.
  ///
  /// This method searches for the specified [query] in the [columnName] of the [tableName] and returns
  /// a list of items that match the search criteria. It uses the LIKE operator for searching and
  /// COLLATE NOCASE for case-insensitivity.
  ///
  /// Parameters:
  /// - [item]: An instance of ISQLiteItem representing the database table schema.
  /// - [columnName]: The name of the column to search in.
  /// - [query]: The search query to match against the specified column.
  /// - [limit]: (Optional) The maximum number of results to return.
  ///
  /// Returns a list of ISQLiteItem objects that match the search criteria.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<ISQLiteItem> searchResults = await search(
  ///   MyDatabaseItem(), // Replace with your ISQLiteItem implementation
  ///   'title',
  ///   'flutter',
  ///   limit: 10,
  /// );
  ///
  /// for (var result in searchResults) {
  ///   print(result.toString());
  /// }
  /// ```

  Future<List<ISQLiteItem>> search(
      ISQLiteItem item, String columnName, String query,
      {int? limit}) async {
    var database = await getOpenDatabase();
    String table = item.getTableName();
    List<ISQLiteItem> results = [];
    var maps = await database.query(
      table,
      columns: null, // Fetch all columns
      where: "$columnName LIKE ? COLLATE NOCASE",
      whereArgs: ['%$query%'],
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  Future<List<ISQLiteItem>> searchColumns(
      ISQLiteItem item, List<String> columnNames, String query,
      {int? limit}) async {
    var database = await getOpenDatabase();
    String table = item.getTableName();
    List<ISQLiteItem> results = [];

    // Construct the "OR" condition for multiple columns
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];
    for (var columnName in columnNames) {
      whereConditions.add("$columnName LIKE ? COLLATE NOCASE");
      whereArgs.add('%$query%');
    }

    // Join the conditions with "OR"
    String whereClause = whereConditions.join(' OR ');

    // Execute the query
    var maps = await database.query(
      table,
      columns: null, // Fetch all columns
      where: whereClause,
      whereArgs: whereArgs,
      limit: limit,
    );

    // Map the results to ISQLiteItem instances
    results = maps.map((map) => item.fromMap(map)).toList();

    return results;
  }

  /// Groups the results of a database query by a specified column and returns the results as a list of [ISQLiteItem] instances.
  ///
  /// This function allows you to dynamically group by any column and select specific columns, optionally sorting and removing duplicates.
  ///
  /// Parameters:
  /// - [item]: The model instance (conforming to [ISQLiteItem]) that defines the table and the `fromMap` method for mapping the query result.
  /// - [columns]: A list of column names to select in the query.
  /// - [groupByColumnName]: The column name used to group the results. Rows with the same value in this column are combined.
  /// - [orderByColumn] (optional): A column name to order the results by. If not provided, no ordering is applied.
  /// - [distinct] (optional): A flag to indicate if duplicates should be removed from the results. Default is `true`.
  ///
  /// Returns:
  /// - A list of [ISQLiteItem] instances, each representing a row from the grouped query result.
  ///
  /// Example Usage:
  /// ```dart
  /// List<String> columns = ['book', 'chapter', 'verse', 'content'];
  /// String groupByColumn = 'book';  // Group by the 'book' column
  /// String orderByColumn = 'chapter';  // Order by the 'chapter' column
  /// bool removeDuplicates = true;  // Remove duplicates from results
  ///
  /// List<ISQLiteItem> items = await groupBy(
  ///   BookCozens(),
  ///   columns,
  ///   groupByColumn,
  ///   orderByColumn: orderByColumn,  // Provide the column for ordering
  ///   distinct: removeDuplicates,  // Optional flag for duplicates
  /// );
  /// ```
  Future<List<ISQLiteItem>> groupBy(
      ISQLiteItem item, List<String> columns, String groupByColumnName,
      {String? orderByColumn, bool distinct = true}) async {
    var database = await getOpenDatabase();
    String tableName = item.getTableName();

    // Dynamically construct the SQL query with GROUP BY
    String query =
        'SELECT ${columns.join(', ')} FROM $tableName GROUP BY $groupByColumnName';

    // Add an ORDER BY clause if orderByColumn is provided
    if (orderByColumn != null) {
      query += ' ORDER BY $orderByColumn';
    }

    // Execute the query
    final List<Map<String, dynamic>> maps = await database.rawQuery(query);

    // Convert the List<Map<String, dynamic>> into a List of ISQLiteItem
    var results = maps.map((map) => item.fromMap(map)).toList();

    // Optional: Remove duplicates (like your toSet().toList() in getSQLBooks)
    if (distinct) {
      results = results.toSet().toList();
    }

    return results;
  }

  Future<int> getCount(ISQLiteItem item) async {
    var db = await getOpenDatabase();
    var count =
        await db.rawQuery('SELECT COUNT(*) FROM ${item.getTableName()}');
    var total = Sqflite.firstIntValue(count) ?? 0;
    return total;
  }

  Future<ISQLiteItem?> getFirstItem(ISQLiteItem item) async {
    final db = await getOpenDatabase();
    final tableName = item.getTableName();

    // Query the table to get the very first row
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT * FROM $tableName LIMIT 1',
    );

    // Return the first item if it exists, otherwise null
    if (results.isNotEmpty) {
      return item.fromMap(results.first);
    }

    return null;
  }

  Future<ISQLiteItem?> getItemByListIndex(ISQLiteItem item, int index) async {
    var db = await getOpenDatabase();

    // Using LIMIT and OFFSET to get the row at the specified index
    var maps = await db.query(
      item.getTableName(),
      limit: 1, // Limit the query to 1 result
      offset: index, // Skip the first 'index' rows to get to the desired row
    );

    if (maps.isNotEmpty) {
      return item
          .fromMap(maps.first); // Return the first (and only) matching item
    }
    return null; // Return null if the index is out of range or no data
  }

  //Helpers

  /// Retrieves a paginated list of items from the SQLite database.
  ///
  /// This method fetches a subset of records from the specified table,
  /// based on the provided `limit` (maximum number of rows) and `offset`
  /// (the starting row index).
  ///
  /// - [item]: The table item (implements `ISQLiteItem`) from which to fetch data.
  /// - [limit]: The maximum number of rows to return in the result set.
  /// - [offset]: The starting point in the result set to begin returning records.
  ///
  /// Returns a `Future<List<ISQLiteItem>>` containing a paginated list of records.
  Future<List<ISQLiteItem>> paginate(
      ISQLiteItem item, int limit, int offset) async {
    // Opens the SQLite database.
    var db = await getOpenDatabase();

    // Queries the table with a specified limit and offset.
    var maps =
        await db.query(item.getTableName(), limit: limit, offset: offset);

    // Maps the database rows to the item model and returns the result as a list.
    return maps.map((map) => item.fromMap(map)).toList();
  }

  /// Backs up the current SQLite database to a specified file path.
  ///
  /// This method creates a copy of the existing database file at the given
  /// [backupPath]. If a file already exists at [backupPath], it will be
  /// overwritten.
  ///
  /// Usage:
  /// ```dart
  /// String backupPath = '/path/to/backup/my_database_backup.db';
  /// await backupDatabase(backupPath);
  /// ```
  ///
  /// Throws an exception if the backup operation fails, such as due to
  /// permission issues or an invalid path.
  Future<File> backupDatabase(String backupPath) async {
    // Retrieve the current database file path
    var dbPath = path; // Implement this to return the path of your database

    // Create a File object for the database file and the backup location
    final databaseFile = File(dbPath);
    final backupFile = File(backupPath);

    // Check if the database file exists before proceeding
    if (await databaseFile.exists()) {
      // Create a backup by copying the database file
      await databaseFile.copy(backupPath);
      return backupFile;
    } else {
      throw Exception("Database file does not exist at $dbPath");
    }
  }

  //Initial
  Future<void> createTable(ISQLiteItem item,
      {bool autoIncrement = true}) async {
    final db = await getOpenDatabase();
    final tableName = item.getTableName();
    final primaryKey = item.getPrimaryKeyName();

    final columns = <String>[];
    final map = item.toMap();

    map.forEach((key, value) {
      if (key == primaryKey) {
        if (value is int) {
          if (autoIncrement) {
            columns.add('$key INTEGER PRIMARY KEY AUTOINCREMENT');
          } else {
            columns.add('$key INTEGER');
          }
        } else if (value is String) {
          columns.add('$key TEXT PRIMARY KEY');
        } else if (value is Uint8List) {
          columns.add('$key BLOB'); // Add a BLOB column for byte arrays
        } else {
          if (autoIncrement) {
            columns.add('$key INTEGER PRIMARY KEY AUTOINCREMENT');
          } else {
            columns.add('$key INTEGER');
          }
        }
      } else {
        if (value is int) {
          columns.add('$key INTEGER');
        } else if (value is double) {
          columns.add('$key REAL');
        } else if (value is bool) {
          columns.add('$key INTEGER');
        } else if (value is Uint8List) {
          columns.add('$key BLOB'); // Add a BLOB column for byte arrays
        } else {
          columns.add('$key TEXT');
        }
      }
    });

    final createTableQuery =
        'CREATE TABLE IF NOT EXISTS $tableName (${columns.join(', ')});';

    await db.execute(createTableQuery);
    //start primarykey to 1
    // Check the current sequence value for the table

    // If the current sequence value is 0, reset it to 1
    if (autoIncrement && map.containsKey('id')) {
      var currentSeq = Sqflite.firstIntValue(
              await db.rawQuery('PRAGMA table_info($tableName)')) ??
          0;
      if (currentSeq < 1) {
        await db.rawUpdate(
          'UPDATE sqlite_sequence SET seq = 1 WHERE name = ?',
          [tableName],
        );
      }
    }
  }

  //Static methods
  static Future<bool> isValidDatabaseFile(String filePath) async {
    final file = File(filePath);
    if (!(await file.exists())) {
      return false; // File does not exist
    }
    final headerBytes = await file.openRead(0, 16).first;
    // SQLite database file header
    const List<int> sqliteHeader = [
      0x53,
      0x51,
      0x4c,
      0x69,
      0x74,
      0x65,
      0x20,
      0x66,
      0x6f,
      0x72,
      0x6d,
      0x61,
      0x74,
      0x20,
      0x33,
      0x00
    ];

    return headerBytes.length == sqliteHeader.length &&
        headerBytes
            .every((byte) => byte == sqliteHeader[headerBytes.indexOf(byte)]);
  }

  static Future<Database> getDatabase(String sqliteFilePath,
      {int version = 1}) async {
    initDatabaseLib();
    var database = await openDatabase(sqliteFilePath, version: version);
    return database;
  }

  static bool _init = false;
  static bool initDatabaseLib() {
    if (_init == false) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Initialize FFI
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _init = true;
      }
    }
    return _init;
  }

  static Future<bool> areDatabaseTablesExist(
      String filePath, List<String> tables) async {
    Database database = await getDatabase(filePath);
    String tableNames = tables.map((table) => '"$table"').join(',');
    try {
      var tableQuery = await database.rawQuery(
          'SELECT name FROM sqlite_master WHERE type="table" AND name IN ($tableNames);');

      //printColor('Expected Tables: $tables');
      //printColor('Found Tables: ${tableQuery.map((row) => row['name'])}');

      return tableQuery.length == tables.length;
    } catch (e) {
      // Handle the exception here
      //printError('Error occurred while checking for tables: $e');
      return false; // Or any other appropriate action
    }
  }

  static Future<List<Map<String, dynamic>>?> getTableInfo(
      String filePath, String tableName) async {
    Database db = await getDatabase(filePath);
    final List<Map<String, dynamic>> tableInfo =
        await db.rawQuery("PRAGMA table_info($tableName);");

    // If the table does not exist, the result will be an empty list.
    // You can check if the list is empty and handle it accordingly.
    if (tableInfo.isEmpty) {
      return null; // Or you can return an empty list or handle the absence of the table in another way.
    }

    return tableInfo;
  }
}
