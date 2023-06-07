import 'package:isar/isar.dart';

import 'fast_hash.dart';

part 'user.g.dart';

enum Gender {
  secrecy,
  male,
  female,
}

@embedded
class Address {
  String? country;
  String? province;
  String? city;
  String? street;
  String? post;
}

@collection
class User {
  // Id id = Isar.autoIncrement; // 你也可以用 id = null 来表示 id 是自增的

  // Id? id;

  String? id;
  // 每一个 Collection 类都必须定义一个 Id 类型的 Id 属性，以便唯一指代一个对象。
  Id get isarId => fastHash(id!);

  String? name;

  // byte 类型不支持空值。
  late byte age; // 0~255

  // 枚举的索引以 byte 类型被保存。性能很高但不支持可空的枚举。
  // @enumerated // 等价于 @Enumerated(EnumType.ordinal)
  @Enumerated(EnumType.ordinal)
  late Gender gender;

  Address? address;

  DateTime? createTime;
}
