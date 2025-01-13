import 'package:sqlite_flutter_pcl/sqlite_flutter_pcl.dart';

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
      for (var t in newList) {
        t.id = 0;
      }
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
    return 'TYPE: ${lastItem?.toString()} NEW: ${newList.length} | UPDATE:  ${updateList.length}';
  }
}
