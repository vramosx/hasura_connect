import 'dart:async';
import 'dart:convert';

import 'dart:math';
import 'dart:html';
import 'package:http/http.dart' as http;
import 'hasura_error.dart';
import 'snapshot.dart';

class HasuraConnect {
  final _controller = StreamController.broadcast();
  final Map<String, Snapshot> _snapmap = {};

  WebSocket _channelPromisse;
  bool _isDisconnected = false;
  bool isConnected = false;
  Completer<bool> _onConnect = Completer<bool>();

  final String url;

  final Future<String> Function() token;

  HasuraConnect(this.url, {this.token});

  final _init = {
    "payload": {
      "headers": {"content-type": "application/json"}
    },
    "type": 'connection_init'
  };

  String get ramdomKey {
    var rand =  Random();
    var codeUnits =  List.generate(8, (index) {
      return rand.nextInt(33) + 89;
    });

    return  String.fromCharCodes(codeUnits);
  }

  String _generateBase(String query) {
    query = query.replaceAll(RegExp("[^a-zA-Z0-9 -]"), "").replaceAll(" ", "");
    var bytes = utf8.encode(query);
    var base64Str = base64.encode(bytes);
    return base64Str;
  }

  Snapshot subscription(String query,
      {String key, Map<String, dynamic> variables}) {
    if (query.trim().split(" ")[0] != "subscription") {
      query = "subscription $query";
    }

    if (key == null) {
      key = _generateBase(query);
    }

    if (_snapmap.keys.isEmpty) {
      _connect();
    }

    if (_snapmap.containsKey(key)) {
      return _snapmap[key];
    } else {
      if (isConnected) {
        _channelPromisse
            .send(_getDocument(query, key, variables).codeUnits);
      }
      var snap = Snapshot(
          key,
          query,
          variables,
          _controller.stream.where((data) => data["id"] == key).transform(
              StreamTransformer.fromHandlers(handleData: (data, sink) {
            if (data["type"] == "data") {
              sink.add(data['payload']);
            } else if (data["type"] == "error") {
              if ((data["payload"] as Map).containsKey("errors")) {
                sink.addError(
                    HasuraError.fromJson(data["payload"]["errors"][0]));
              } else {
                sink.addError(HasuraError.fromJson(data["payload"]));
              }
            }
          })), () {
        _stopStream(key);
        _snapmap.remove(key);
        if (_snapmap.keys.isEmpty) {
          _disconnect();
        }
      }, (snapshotInternal) {
        _stopStream(key);
        if (isConnected) {
          _channelPromisse
              .send(_getDocument(snapshotInternal.query, snapshotInternal.key, snapshotInternal.variables).codeUnits);
        }
      });

      _snapmap[key] = snap;
      return snap;
    }
  }

  _stopStream(String key) {
    var stop = {"id": key, "type": 'stop'};
    if (isConnected)
      _channelPromisse.send(jsonEncode(stop).codeUnits);
  }

  String _getDocument(
      String query, String key, Map<String, dynamic> variables) {
    return jsonEncode({
      "id": key,
      "payload": {
        "query": query,
        "variables": variables,
      },
      "type": 'start'
    });
  }

  Future<void> _connect() async {
    print("connecting...");

    try {
      _channelPromisse = await WebSocket(url.replaceFirst("http", "ws"),
          ['graphql-subscriptions']);
      if (token != null) {
        String t = await token();
        if (t != null)
          (_init["payload"] as Map)["headers"]["Authorization"] = t;
      }

      _channelPromisse.send(jsonEncode(_init).codeUnits);
      var _sub = _channelPromisse.onMessage.listen((event) {
        dynamic data = jsonDecode(event.data);
        if (data["type"] == "data" || data["type"] == "error") {
          _controller.add(data);
        } else if (data["type"] == "connection_ack") {
          print("CONNECTED");
          isConnected = true;
          for (var key in _snapmap.keys) {
            _channelPromisse.send(_getDocument(_snapmap[key].query,
                    _snapmap[key].key, _snapmap[key].variables)
                .codeUnits);
          }
          //_onConnect.complete(true);
        }
      });
      _sub.onError((e) {
        print(e);
      });
      await _channelPromisse.onOpen;
      await _sub.cancel();
      isConnected = false;
      if (!_isDisconnected) {
        await Future.delayed(Duration(milliseconds: 3000));
        if (_onConnect.isCompleted) _onConnect = Completer<bool>();
        _connect();
      }
    } catch (e) {
      if (!_isDisconnected) {
        await Future.delayed(Duration(milliseconds: 3000));

        if (_onConnect.isCompleted) {
          _onConnect = Completer<bool>();
        }
        await _connect();
      }
    }
  }

  void _disconnect() {
    print("_disconnect");
    _isDisconnected = true;
    if (_channelPromisse?.onClose != null) {
      _channelPromisse.close();
    }
  }

  Future query(String doc, {Map<String, dynamic> variables}) async {
    if (doc.trimLeft().split(" ")[0] != "query") {
      doc = "query $doc";
    }
    Map<String, dynamic> jsonMap = {
      'query': doc,
      'variables': variables,
    };
    return _sendPost(jsonMap);
  }

  Future mutation(String doc, {Map<String, dynamic> variables}) async {
    if (doc.trim().split(" ")[0] != "mutation") {
      doc = "mutation $doc";
    }
    Map<String, dynamic> jsonMap = {
      'query': doc,
      'variables': variables,
    };
    return _sendPost(jsonMap);
  }

  Future _sendPost(Map<String, dynamic> jsonMap) async {
    String jsonString = jsonEncode(jsonMap);
    List<int> bodyBytes = utf8.encode(jsonString);
    http.Response response;
    if (token != null) {
      String t = await token();
      if (t != null) 
      response = await http.post(Uri.parse(url),headers: {"Content-type": "application/json","Accept": "application/json","Authorization": t},);

    }

    Map json = jsonDecode(response.body);

    if (json.containsKey("errors")) {
      throw HasuraError.fromJson(json["errors"][0]);
    }
    return json;
  }

  void dispose() {
    _disconnect();
    _controller.close();
    _snapmap.clear();
  }
}
