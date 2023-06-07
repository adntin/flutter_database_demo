import 'package:isar/isar.dart';

import 'fast_hash.dart';

part 'message.g.dart';

@collection
class Message {
  String? id;
  // 每一个 Collection 类都必须定义一个 Id 类型的 Id 属性，以便唯一指代一个对象。
  Id get isarId => fastHash(id!);

  String? content;

  DateTime? createTime;
}
