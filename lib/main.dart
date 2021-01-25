import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

const String SETTINGS_BOX = "settings";
const String API_BOX = "api_data";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(SETTINGS_BOX);
  await Hive.openBox(API_BOX);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(Hive.box(SETTINGS_BOX).get("welcome_shown"));
    return ValueListenableBuilder(
      valueListenable: Hive.box(SETTINGS_BOX).listenable(),
      builder: (context, box, child) =>
          box.get('welcome_shown', defaultValue: false)
              ? HomePage()
              : WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Welcome Page"),
            ElevatedButton(
              onPressed: () async {
                var box = Hive.box(SETTINGS_BOX);
                box.put("welcome_shown", true);
              },
              child: Text("Get Started"),
            )
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home page'),
      ),
      body: FutureBuilder(
        future: ApiService().getPosts(),
        builder: (context, snapshot) {
          if(!snapshot.hasData) return CircularProgressIndicator();
          final List posts = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              Text("This is a home page"),
              ...posts.map((p)=>ListTile(
                title: Text(p['title']),
              )),
              ElevatedButton(
                onPressed: () {
                  Hive.box(SETTINGS_BOX).put('welcome_shown',false);
                },
                child: Text("Clear"),
              )
            ],
          );
        }
      ),
    );
  }
}


class ApiService {
  Future getPosts() async {
    final posts = Hive.box(API_BOX).get('posts',defaultValue: []);
    if(posts.isNotEmpty) return posts;
    final http.Response res = await http.get('https://jsonplaceholder.typicode.com/posts');
    final resjson = jsonDecode(res.body);
    Hive.box(API_BOX).put("posts", resjson);
    return resjson;
  }
}