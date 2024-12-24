

abstract class ISQLiteItem {
  String getTableName();
  int? getPrimaryKey();
  String getPrimaryKeyName();
  Map<String, dynamic> toMap();
  ISQLiteItem fromMap(Map<String, dynamic> map);
}



