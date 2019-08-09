import 'package:flutter_web/material.dart';
import 'package:websocket/src/websocket_browser.dart';
import 'package:hasura_connect/hasura_connect.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  void a() async {

   
    HasuraConnect conn =
        HasuraConnect('https://mvp-rtc-project.herokuapp.com/v1/graphql');

    String docSubscription = """
  subscription algumaCoisa{
  users {
    user_id
    user_email
    user_password
  }
}
""";

    Snapshot snap = conn.subscription(docSubscription);
    snap.stream.listen((data) {
      print("CONECTADO");
      // d("AAAAAAAAAA");
    }).onError((err) {
      print("DEU ERRO");
      // d("DEU ERRO");
    });
  }

  @override
  void initState() {
    a();

    super.initState();
  }

  void d(String x) {
    showDialog(
        context: context,
        builder: (e) => Column(
              children: <Widget>[Text("aaaaaaaaaa: $x")],
            ));
  }

  @override
  Widget build(BuildContext context) {
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (choose the "Toggle Debug Paint" action
          // from the Flutter Inspector in Android Studio, or the "Toggle Debug
          // Paint" command in Visual Studio Code) to see the wireframe for each
          // widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '',
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
