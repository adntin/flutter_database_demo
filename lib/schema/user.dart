import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // 你也可以用 id = null 来表示 id 是自增的

  String? name;

  int? age;
}
