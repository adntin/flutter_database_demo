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
          // SafeArea(
          //   child: ElevatedButton(
          //     onPressed: _handleMultiIsolate,
          //     child: const Text('Multi Isolate'),
          //   ),
          // ),
        ],
      ),
      // body: Column(
      //   children: [
      //     // ListView.builder(
      //     //   itemCount: users?.length,
      //     //   itemBuilder: (BuildContext context, int index) {
      //     //     if (users == null) {
      //     //       return null;
      //     //     }
      //     //     User user = users![index];
      //     //     return ListTile(
      //     //       leading: CircleAvatar(child: Text(user.id.toString())),
      //     //       title: Text(user.name!),
      //     //       subtitle: Text(user.createTime.toString()),
      //     //       trailing: InkWell(
      //     //         child: const Icon(Icons.delete_outline),
      //     //         onTap: () => _delete(user.isarId),
      //     //       ),
      //     //       onTap: () => _get(user.isarId),
      //     //     );
      //     //   },
      //     // ),
      //     ElevatedButton(
      //       onPressed: _handleMultiIsolate,
      //       child: const Text('Multi Isolate'),
      //     ),
      //   ],
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: _put,
        tooltip: 'Insert or Update',
        child: const Icon(Icons.add),
      ),
    );
  }
}
