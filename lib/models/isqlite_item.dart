import '../sqlite_connetion.dart';

abstract class ISQLiteItem {
  String getTableName();
  int? getPrimaryKey();
  String getPrimaryKeyName();
  Map<String, dynamic> toMap();
  ISQLiteItem fromMap(Map<String, dynamic> map);
}

abstract class ISQLiteItemExtended implements ISQLiteItem {
  int? id;
  String? uniqueId;
  int? rowNumber;
  String getUniqueIdName();

  /// Sample '${title ?? ""}|${value ?? ""}'
  String toJoinString();
}

class SQLiteItemBatch {
  List<ISQLiteItemExtended> newList = [];
  List<ISQLiteItemExtended> updateList = [];
  ISQLiteItemExtended? lastItem;

  Future<bool> saveAsync(SQLiteConnection db) async {
    bool hasSaved = false;
    if (hasItems() == false) {
      return hasSaved;
    }
    if (newList.isNotEmpty) {
      await db.insertAll(newList);
      hasSaved = true;
    }
    if (updateList.isNotEmpty) {
      await db.updateAll(updateList);
      hasSaved = true;
    }
    return hasSaved;
  }

  void save(SQLiteConnection db) async {
    await saveAsync(db);
  }

  bool hasItems() {
    return newList.isNotEmpty || updateList.isNotEmpty;
  }

  String toPrintString() {
    return 'NEW: ${newList.length} | UPDATE:  ${updateList.length}';
  }
}
