import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketProvider extends ChangeNotifier {
  String _url = "";
  bool _isConnected = false;
  bool _shouldStreamData = false;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _errorWhileConnecting = false;
  bool _isLoading = false;

  bool get shouldStreamData => _shouldStreamData;
  bool get errorWhileConnecting => _errorWhileConnecting;
  String get url => _url;
  bool get isConnected => _isConnected;
  bool get streamData => _shouldStreamData;
  bool get isLoading => _isLoading;

  /// Set the WebSocket URL before connecting
  void setConnectionUrl(String connectionURL) {
    _url = connectionURL;
    notifyListeners();
  }

  /// Establish a WebSocket connection
  Future<bool> connect() async {
    if (_url.isEmpty) {
      debugPrint("WebSocket URL not set!");
      return false;
    }

    _isLoading = true;
    _errorWhileConnecting = false;
    notifyListeners();

    try {
      var uri = Uri.parse(_url);
      debugPrint(url);
      if (uri.hasFragment) {
        uri = uri.replace(fragment: '');
      }
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _isConnected = true;
      _isLoading = false;
      notifyListeners();

      _subscription = _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          debugPrint("WebSocket error: $error");
        },
        onDone: () {},
        cancelOnError: true,
      );

      debugPrint("Connected to $_url");
      return true;
    } catch (e) {
      debugPrint("Connection failed: $e");
      _errorWhileConnecting = true;
      _isLoading = false;
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  void sendMessage(String message) {
    // debugPrint("Sending message: $message");
    if (_channel != null && _isConnected && _shouldStreamData) {
      try {
        _channel!.sink.add(message);
        debugPrint(message);
      } catch (e) {
        debugPrint("Send failed: $e");
      }
    } else {
      debugPrint("Not connected — message not sent.");
    }
  }

  /// Handle incoming messages
  void _handleMessage(dynamic message) {
    if (_shouldStreamData) {
      debugPrint("Received message: $message");
      // You can notify UI or process data here
    }
  }

  /// Clean up connection
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close(status.normalClosure);
    _isConnected = false;
    notifyListeners();
  }

  /// Handle disconnection logic
  void _handleDisconnect({bool error = false}) {
    _isConnected = false;
    _errorWhileConnecting = error;
    notifyListeners();
  }

  void setShouldStreamData(bool value) {
    _shouldStreamData = value;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
