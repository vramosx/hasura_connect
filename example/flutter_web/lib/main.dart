import 'dart:async';

import 'package:flutter_web/material.dart';
import 'package:hasura_connect/hasura_connect.dart';
import 'user_model.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HasuraConnect _hasuraConnect;
  final hasuraFlux = StreamController<Map<String, dynamic>>();
  Future<dynamic> future;
  List<User> _users;
  final String subscription = '''
  subscription userList(\$limit: Int!) {
  users(limit: \$limit) {
    user_id
  }
}''';
  final String query = '''
query userList(\$limit: Int!) {
  users(limit: \$limit) {
    user_id
  }
}''';

  @override
  void initState() {
    super.initState();

    _hasuraConnect =
        HasuraConnect('https://mvp-rtc-project.herokuapp.com/v1/graphql');
    future = _hasuraConnect.query(query).then(print).catchError(print);
    // _hasuraConnect
    //     .subscription(query, variables: {'limit': 22})
    //     .stream
    //     .distinct()
    //     .listen(hasuraFlux.add);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<dynamic>(
          future: future,
          builder: (conext, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            _users = (snapshot?.data['data']['users'] as List)
                .map((v) => User.fromJson(v))
                ?.toList();
            return ListView.builder(
              itemCount: _users.length,
              itemBuilder: (contex, index) => ListTile(
                leading: Text(_users[index].userId.toString() ?? ""),
              ),
            );
          }),
    );
    // return Scaffold(
    //   body: StreamBuilder<Map<String, dynamic>>(
    //       stream: hasuraFlux.stream,
    //       builder: (conext, snapshot) {
    //         if (!snapshot.hasData) {
    //           return Center(child: CircularProgressIndicator());
    //         }
    //         _users = (snapshot?.data['data']['users'] as List)
    //             .map((v) => User.fromJson(v))
    //             ?.toList();
    //         return ListView.builder(
    //           itemCount: _users.length,
    //           itemBuilder: (contex, index) => ListTile(
    //             leading: Text(_users[index].userId.toString() ?? ""),
    //           ),
    //         );
    //       }),
    // );
  }
}
