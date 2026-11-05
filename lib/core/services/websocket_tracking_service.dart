import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../network/api_client.dart';

class OrderUpdateEvent {
  final String orderId;
  final String status;
  final String? deliveryOtp;
  final DateTime timestamp;

  const OrderUpdateEvent({
    required this.orderId,
    required this.status,
    this.deliveryOtp,
    required this.timestamp,
  });

  factory OrderUpdateEvent.fromJson(Map<String, dynamic> json) {
    final dtStr = json['timestamp']?.toString();
    return OrderUpdateEvent(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      deliveryOtp: json['deliveryOtp']?.toString(),
      timestamp: dtStr != null
          ? (DateTime.tryParse(dtStr) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class DriverLocationEvent {
  final String orderId;
  final String driverId;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final DateTime recordedAt;

  const DriverLocationEvent({
    required this.orderId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.recordedAt,
  });

  factory DriverLocationEvent.fromJson(Map<String, dynamic> json) {
    final dtStr = json['recordedAt']?.toString();
    return DriverLocationEvent(
      orderId: json['orderId']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      recordedAt: dtStr != null
          ? (DateTime.tryParse(dtStr) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class WebSocketTrackingService {
  WebSocket? _socket;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  final Set<String> _subscribedRooms = {};

  final StreamController<OrderUpdateEvent> _orderUpdatesController =
      StreamController<OrderUpdateEvent>.broadcast();
  final StreamController<DriverLocationEvent> _driverLocationsController =
      StreamController<DriverLocationEvent>.broadcast();

  Stream<OrderUpdateEvent> get orderUpdates => _orderUpdatesController.stream;
  Stream<DriverLocationEvent> get driverLocations =>
      _driverLocationsController.stream;

  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;

  /// Connect to the live duplex gateway
  Future<void> connect() async {
    if (_isDisposed) return;
    if (isConnected) return;

    try {
      final wsUri = Uri.parse(ApiConfig.wsUrl);
      final token = globalApiClient.authToken;
      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      _socket = await WebSocket.connect(
        wsUri.toString(),
        headers: headers.isNotEmpty ? headers : null,
      ).timeout(const Duration(seconds: 10));

      _startPingHeartbeat();

      // Handshake authentication frame
      if (token != null && token.isNotEmpty) {
        _send({
          'action': 'auth',
          'token': token,
        });
      }

      // Re-subscribe to any previously active rooms
      for (final room in _subscribedRooms) {
        _send({'action': 'subscribe', 'room': room});
      }

      _socket!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final Map<String, dynamic> msg = jsonDecode(raw.toString());
      final event = msg['event']?.toString();
      final data = msg['data'];

      if (event == 'pong') {
        // Heartbeat acknowledged
        return;
      }

      if (event == 'order:update' && data is Map<String, dynamic>) {
        _orderUpdatesController.add(OrderUpdateEvent.fromJson(data));
      } else if (event == 'driver:location' && data is Map<String, dynamic>) {
        _driverLocationsController.add(DriverLocationEvent.fromJson(data));
      }
    } catch (e) {
      debugPrint('WebSocket message parse error: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _cleanupSocket();
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WebSocket connection closed.');
    _cleanupSocket();
    _scheduleReconnect();
  }

  void _startPingHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected) {
        _send({'action': 'ping'});
      }
    });
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed && !isConnected) {
        connect();
      }
    });
  }

  void _send(Map<String, dynamic> data) {
    if (isConnected) {
      try {
        _socket!.add(jsonEncode(data));
      } catch (e) {
        debugPrint('WebSocket send error: $e');
      }
    }
  }

  /// Subscribe to real-time order tracking room
  void subscribeOrder(String orderId) {
    final room = 'order:$orderId';
    _subscribedRooms.add(room);
    if (!isConnected) {
      connect();
    } else {
      _send({'action': 'subscribe', 'room': room});
    }
  }

  /// Unsubscribe from order tracking room
  void unsubscribeOrder(String orderId) {
    final room = 'order:$orderId';
    _subscribedRooms.remove(room);
    if (isConnected) {
      _send({'action': 'unsubscribe', 'room': room});
    }
  }

  void _cleanupSocket() {
    _pingTimer?.cancel();
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _cleanupSocket();
    _orderUpdatesController.close();
    _driverLocationsController.close();
  }
}

final wsTrackingService = WebSocketTrackingService();

