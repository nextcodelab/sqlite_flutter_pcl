import 'package:sqlite_flutter_pcl/sqlite_flutter_pcl.dart';

Future<String> getTemporaryDatabasePath() async {
    final directory = await getTemporaryDirectory();
    final path = join(directory.path, 'your_database.db');
    print(path);
    return path;
  }
