

import 'package:sqlite_flutter_pcl/sqlite_flutter_pcl.dart';

abstract class ISQLiteItemExtended implements ISQLiteItem {
  int? id;
  String? uniqueId;
  int? rowNumber;
  String getUniqueIdName();

  /// Sample '${title ?? ""}|${value ?? ""}'
  String toJoinString();
}