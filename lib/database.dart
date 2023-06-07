import 'package:flutter_database_demo/schema/message.dart';
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
      [UserSchema, MessageSchema],
      directory: dir.path,
      name: 'my_database',
    );

    // // 观察 Collection
    // Stream<void> userChanged = _instance.users.watchLazy();
    // userChanged.listen((event) {
    //   print('A User changed');
    // });
    // // 观察查询
    // Query<User> usersWithA =
    //     _instance.users.filter().nameStartsWith('J').build();
    // Stream<List<User>> queryChanged = usersWithA.watch(fireImmediately: true);
    // queryChanged.listen((users) {
    //   print('Users with A are: $users');
    // });
  }
}
