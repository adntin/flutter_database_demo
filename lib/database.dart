import 'package:flutter_database_demo/schema/user.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class Database {
  static late Isar _instance;
  static Isar get instance => _instance;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    print('数据库目录: ${dir.path}');
    _instance = await Isar.open(
      [UserSchema],
      directory: dir.path,
      name: 'my_database',
    );
  }
}
