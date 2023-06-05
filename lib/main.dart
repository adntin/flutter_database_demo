import 'package:flutter/material.dart';
import 'package:flutter_database_demo/database.dart';
import 'package:flutter_database_demo/schema/user.dart';
import 'package:isar/isar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Database.init();
  runApp(const MyApp());
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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
    final newUser = User()
      ..name = 'Jane Doe'
      ..age = 36;
    await Database.instance.writeTxn(() async {
      await Database.instance.users.put(newUser); // 将新用户数据写入到 Isar
    });
  }

  @override
  void initState() {
    super.initState();
    Database.instance.users.where().findAll().then((value) {
      setState(() => users = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              users == null ? '正在读取数据库' : 'Users count: ${users!.length}',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _put,
        tooltip: 'Insert or Update',
        child: const Icon(Icons.add),
      ),
    );
  }
}
