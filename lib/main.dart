import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_database_demo/database.dart';
import 'package:flutter_database_demo/schema/message.dart';
import 'package:flutter_database_demo/schema/user.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  // 非常重要, 没有下面这句初始化, 会报错
  // Binding has not yet been initialized.
  // The "instance" getter on the ServicesBinding binding mixin is only available once that binding has been initialized.
  // Typically, this is done by calling "WidgetsFlutterBinding.ensureInitialized()" or "runApp()" (the latter calls the former). Typically this call is done in the "void main()" method. The "ensureInitialized" method is idempotent; calling it multiple times is not harmful. After calling that method, the "instance" getter will return the binding.
  // In a test, one can call "TestWidgetsFlutterBinding.ensureInitialized()" as the first line in the test's "main()" method to initialize the binding.
  // If ServicesBinding is a custom binding mixin, there must also be a custom binding class, like WidgetsFlutterBinding, but that mixes in the selected binding, and that is the class that must be constructed before using the "instance" getter.
  WidgetsFlutterBinding.ensureInitialized();
  await Database.init();
  runApp(const MyApp());
}

// 函数将会在新的 isolate 中被执行
Future createDummyMessages(RootIsolateToken rootIsolateToken) async {
  print('[isolate] 函数开始');
  // 非常重要, 没有下面这句初始化, 会报错
  // https://zhuanlan.zhihu.com/p/603202938
  // 说明: getApplicationDocumentsDirectory 是通过 Platform Channels 调用原生 API 获取文件路径
  // 在 Flutter 3.7 之前，我们只能从 root isolate 去调用 Platform Channels，如果你尝试从其他 isolate 去调用 Platform Channels, 会报错
  // 从 Flutter 3.7 开始，Flutter 会通过新增的 BinaryMessenger 来实现非 root isolate，也可以和 Platform Channels 直接通信
  // 现在 Flutter 3.7 引入了 RootIsolateToken 和 BackgroundIsolateBinaryMessenger 两个对象，当 background isolate 调用 Platform Channels 时，background isolate 需要和 root isolate 建立关联
  // 在 Flutter 3.7 上 ，如果 background isolate 调用 Platform Channels 没有关联 root isolate，会看到如下错误
  // Bad state: The BackgroundIsolateBinaryMessenger.instance value is invalid until BackgroundIsolateBinaryMessenger.ensureInitialized is executed.
  // 如果把 "RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;" 写到了 background isolate 执行的方法里, 会看到如下错误
  // Null check operator used on a null value
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  final dir = await getApplicationDocumentsDirectory();
  print('[isolate] 数据库目录: ${dir.path}');
  final isar = await Isar.open(
    [UserSchema, MessageSchema],
    directory: dir.path,
    name: 'my_database',
  );
  // var count = Random().nextInt(10); // Value is >= 0 and < 10.
  var count = Random().nextInt(10000) + 10000; // Value is >= 10000 and < 20000.
  final messages = List.generate(
      count,
      (i) => Message()
        ..id = i.toString()
        ..content = 'Message $i'
        ..createTime = DateTime.now());

  print('[isolate] 异步事务, 开始');
  await isar.writeTxn(() async {
    print('[isolate] 异步事务, 删除开始');
    await isar.messages.where().deleteAll();
    print('[isolate] 异步事务, 删除结束');
    print('[isolate] 异步事务, 写入开始');
    await isar.messages.putAll(messages);
    print('[isolate] 异步事务, 写入结束');
  });
  print('[isolate] 异步事务, 结束');

  // print('[isolate] 同步事务, 开始');
  // isar.writeTxnSync(() {
  //   print('[isolate] 同步事务, 删除开始');
  //   isar.messages.where().deleteAllSync();
  //   print('[isolate] 同步事务, 删除结束');
  //   print('[isolate] 同步事务, 写入开始');
  //   isar.messages.putAllSync(messages);
  //   print('[isolate] 同步事务, 写入结束');
  // });
  // print('[isolate] 同步事务, 结束');

  print('[isolate] 函数结束');
  return 'compute finished';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<User>? users;

  void _put() async {
    final address = Address()
      ..country = "中国"
      ..province = "福建"
      ..city = "厦门"
      ..street = "xx街道xx小区xx楼xx室"
      ..post = "361000";
    final newUser = User()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..name = 'Jane Doe'
      ..age = 36
      ..gender = Gender.male
      ..address = address
      ..createTime = DateTime.now();
    await Database.instance.writeTxn(() async {
      await Database.instance.users.put(newUser); // 将新用户数据写入到 Isar
      load();
    });
  }

  void _delete(int id) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Please Confirm'),
          content: const Text('Are you sure to remove the record?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Database.instance.writeTxn(() async {
                  await Database.instance.users.delete(id);
                  load();
                });
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _get(int id) async {
    User? user = await Database.instance.users.get(id);
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text(user!.name!),
            content: Text('id: ${user.id}, age: ${user.age}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void load() async {
    List<User> items = await Database.instance.users.where().findAll();
    setState(() {
      users = items;
    });
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  _handleMultiIsolate() {
    // 订阅数据库中消息表的变化
    Stream<void> messageChanged = Database.instance.messages.watchLazy();
    messageChanged.listen((_) {
      print('omg the messages changed!');
    });

    // 创建一个新的 isolate，写入 10000 条讯息到数据库
    RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    // 方法1
    compute(createDummyMessages, rootIsolateToken).then((value) {
      print('Compute isolate then: $value');
    }).catchError((error) {
      print('Compute isolate error: $error');
    });
    // 方法2
    // Isolate.spawn(createDummyMessages, rootIsolateToken);
    // Isolate.spawn((rootIsolateToken) {
    //   createDummyMessages(rootIsolateToken);
    // }, rootIsolateToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: users?.length,
              itemBuilder: (BuildContext context, int index) {
                if (users == null) {
                  return null;
                }
                User user = users![index];
                return ListTile(
                  leading: CircleAvatar(child: Text(user.id.toString())),
                  title: Text(user.name!),
                  subtitle: Text(user.createTime.toString()),
                  trailing: InkWell(
                    child: const Icon(Icons.delete_outline),
                    onTap: () => _delete(user.isarId),
                  ),
                  onTap: () => _get(user.isarId),
                );
              },
            ),
          ),
          SafeArea(
            child: ElevatedButton(
              onPressed: _handleMultiIsolate,
              child: const Text('Multi Isolate'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _put,
        tooltip: 'Insert or Update',
        child: const Icon(Icons.add),
      ),
    );
  }
}
