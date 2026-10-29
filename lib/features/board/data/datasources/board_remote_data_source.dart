import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class BoardRemoteDataSource {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _closing = false;

  Future<void> connect(
    String endpoint,
    void Function(Map<String, dynamic>) onMessage,
  ) async {
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        !uri.hasScheme ||
        !const {'ws', 'wss'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const FormatException('Enter a valid ws:// or wss:// URL.');
    }
    await disconnect();
    _closing = false;
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    await channel.ready;
    _subscription = channel.stream.listen(
      (dynamic message) {
        if (message is! String) return;
        try {
          final decoded = jsonDecode(message);
          if (decoded is Map<String, dynamic>) {
            onMessage(decoded);
          } else {
            onMessage({
              'type': 'connection.error',
              'reason':
                  'Received a WebSocket message that was not a JSON object.',
            });
          }
        } on FormatException {
          onMessage({
            'type': 'connection.error',
            'reason': 'Received malformed JSON from the WebSocket server.',
          });
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_closing) {
          onMessage({
            'type': 'connection.error',
            'reason': 'WebSocket connection failed: $error',
          });
        }
      },
      onDone: () {
        if (!_closing) {
          onMessage({
            'type': 'connection.closed',
            'reason': 'WebSocket connection was closed by the server.',
          });
        }
      },
    );
  }

  void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  Future<void> disconnect() async {
    _closing = true;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }
}
