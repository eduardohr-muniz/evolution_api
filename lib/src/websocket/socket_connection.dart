import 'dart:developer';
import 'dart:convert';
import 'package:evolution_api/src/enums/events.dart';
import 'package:evolution_api/src/responses/event_response.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef EventCallback = void Function(EventResponse response);

class SocketConnection {
  final String baseUrl;
  final String instanceName;
  final String apiKey;
  IO.Socket? _socket;
  final Map<EvoEvents, List<EventCallback>> _callbacks = {};

  SocketConnection({required this.baseUrl, required this.instanceName, required this.apiKey});

  void connect() {
    if (_socket != null) {
      log('⚠️ Socket is already connected', name: 'SocketConnection');
      return;
    }

    try {
      _socket = IO.io(
        '$baseUrl/$instanceName',
        IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders({'apikey': apiKey}).setPath('/socket.io/').enableReconnection().setReconnectionAttempts(5).setReconnectionDelay(1000).setReconnectionDelayMax(5000).build(),
      );

      _setupSocketListeners();
      log('✅ Socket connection initialized', name: 'SocketConnection');
    } catch (e, stack) {
      log('❌ Error initializing socket connection: $e', name: 'SocketConnection', error: e, stackTrace: stack);
      rethrow;
    }
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      log('✅ Socket connected', name: 'SocketConnection');
    });

    _socket?.onDisconnect((_) {
      log('⚠️ Socket disconnected', name: 'SocketConnection');
    });

    _socket?.onConnectError((error) {
      log('❌ Socket connection error: $error', name: 'SocketConnection');
    });

    _socket?.onError((error) {
      log('❌ Socket error: $error', name: 'SocketConnection');
    });

    _socket?.onReconnect((_) {
      log('🔄 Socket reconnected', name: 'SocketConnection');
    });

    _socket?.onReconnectAttempt((attempt) {
      log('🔄 Socket reconnection attempt: $attempt', name: 'SocketConnection');
    });

    _socket?.onReconnectError((error) {
      log('❌ Socket reconnection error: $error', name: 'SocketConnection');
    });

    _socket?.onReconnectFailed((_) {
      log('❌ Socket reconnection failed', name: 'SocketConnection');
    });

    for (var event in EvoEvents.values) {
      _socket?.on(event.socketEvent, (data) {
        log('🔄 Socket event: $event ${data.toString()}', name: 'SocketConnection');
        final callbacks = _callbacks[event];
        if (callbacks != null) {
          for (var callback in callbacks) {
            final response = _parseEventData(data);
            callback(response);
          }
        }
      });
    }
  }

  EventResponse _parseEventData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return EventResponse(data: data, event: EvoEvents.values.firstWhere((e) => e.socketEvent == data['event'], orElse: () => EvoEvents.UNKNOWN));
    } else if (data is String) {
      try {
        final Map<String, dynamic> jsonData = json.decode(data);
        return EventResponse(data: jsonData, event: EvoEvents.values.firstWhere((e) => e.socketEvent == jsonData['event'], orElse: () => EvoEvents.UNKNOWN));
      } catch (e) {
        log('⚠️ Error parsing event data: $e', name: 'SocketConnection');
        return EventResponse(data: {'data': data}, event: EvoEvents.UNKNOWN);
      }
    }
    return EventResponse(data: {'data': data}, event: EvoEvents.UNKNOWN);
  }

  void onEvent(EvoEvents event, EventCallback callback) {
    _callbacks[event] ??= [];
    _callbacks[event]!.add(callback);
  }

  void offEvent(EvoEvents event, EventCallback callback) {
    _callbacks[event]?.remove(callback);
  }

  void disconnect() {
    if (_socket == null) {
      log('⚠️ Socket is not connected', name: 'SocketConnection');
      return;
    }

    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _callbacks.clear();
      log('✅ Socket disconnected and disposed', name: 'SocketConnection');
    } catch (e, stack) {
      log('❌ Error disconnecting socket: $e', name: 'SocketConnection', error: e, stackTrace: stack);
      rethrow;
    }
  }

  void emit(String event, dynamic data) {
    if (_socket == null) {
      log('⚠️ Socket is not connected', name: 'SocketConnection');
      return;
    }
    _socket?.emit(event, data);
  }
}
