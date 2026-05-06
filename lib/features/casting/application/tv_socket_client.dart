import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'cast_command.dart';

class TvSocketClient {
  WebSocketChannel? _channel;

  bool get isConnected => _channel != null;

  void connect(Uri endpoint) {
    _channel?.sink.close();
    _channel = WebSocketChannel.connect(endpoint);
  }

  void send(CastCommand command) {
    _channel?.sink.add(jsonEncode(command.toJson()));
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
