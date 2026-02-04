import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  late socket_io.Socket socket;
  bool _isInitialized = false; // Add safe guard
  static String serverUrl =
      'https://fritz-diminishable-disenchantedly.ngrok-free.dev';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null) {
      serverUrl = savedUrl;
    }
  }

  String? _currentRoom;

  void connect() {
    if (_isInitialized && socket.connected) return;

    socket = socket_io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'ngrok-skip-browser-warning': 'true'},
    });
    socket.connect();
    _isInitialized = true;

    socket.onConnect((_) {
      debugPrint('Connected to Socket Server');
      if (_currentRoom != null) {
        debugPrint('Re-joining room: $_currentRoom');
        socket.emit('join_auction', _currentRoom);
      }
    });
  }

  void joinAuction(String room) {
    _currentRoom = room;
    if (_isInitialized) {
      socket.emit('join_auction', room);
    }
  }

  void placeBid(int teamId, int playerId, double amount) {
    if (_isInitialized) {
      socket.emit('place_bid', {
        'teamId': teamId,
        'playerId': playerId,
        'amount': amount,
      });
    }
  }

  void on(String event, Function(dynamic) handler) {
    if (_isInitialized) {
      socket.on(event, handler);
    }
  }

  void disconnect() {
    if (_isInitialized) {
      socket.dispose();
      _isInitialized = false;
    }
  }
}
