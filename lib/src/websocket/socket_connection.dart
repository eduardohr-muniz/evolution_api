import 'dart:developer';
import 'dart:convert';
import 'dart:async';
import 'package:evolution_api/src/enums/events.dart';
import 'package:evolution_api/src/responses/event_response.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef EventCallback = void Function(EventResponse response);

enum ConnectionStatus { disconnected, connecting, connected, reconnecting, failed }

class SocketConnection {
  final String baseUrl;
  final String instanceName;
  final String apiKey;
  io.Socket? _socket;
  final Map<EvoEvents, List<EventCallback>> _callbacks = {};

  // Status da conexão
  ConnectionStatus _status = ConnectionStatus.disconnected;

  // Controle de reconexão
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _connectionTimeoutTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;
  final int _baseReconnectDelay = 1000; // 1 segundo
  final int _maxReconnectDelay = 30000; // 30 segundos
  final int _heartbeatInterval = 30000; // 30 segundos
  final int _connectionTimeout = 10000; // 10 segundos

  // Flag para controle manual de desconexão
  bool _manualDisconnect = false;
  bool _disposed = false;

  SocketConnection({required this.baseUrl, required this.instanceName, required this.apiKey});

  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;
  bool get isConnecting => _status == ConnectionStatus.connecting || _status == ConnectionStatus.reconnecting;

  void connect() {
    if (_disposed) {
      log('⚠️ Socket connection is disposed, cannot connect', name: 'SocketConnection');
      return;
    }

    if (isConnected || isConnecting) {
      log('⚠️ Socket is already connected or connecting', name: 'SocketConnection');
      return;
    }

    _manualDisconnect = false;
    _attemptConnection();
  }

  void _attemptConnection() {
    if (_disposed || _manualDisconnect) return;

    _setStatus(ConnectionStatus.connecting);
    _startConnectionTimeout();

    try {
      _socket = io.io(
        '$baseUrl/$instanceName',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'apikey': apiKey})
            .setPath('/socket.io/')
            .enableReconnection()
            .setReconnectionAttempts(0) // Desabilita reconexão automática do socket.io, vamos gerenciar manualmente
            .setReconnectionDelay(_baseReconnectDelay)
            .setReconnectionDelayMax(_maxReconnectDelay)
            .setTimeout(10000)
            .enableForceNew()
            .build(),
      );

      _setupSocketListeners();
      log('✅ Socket connection attempt started', name: 'SocketConnection');
    } catch (e, stack) {
      log('❌ Error initializing socket connection: $e', name: 'SocketConnection', error: e, stackTrace: stack);
      _handleConnectionError();
    }
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      _cancelConnectionTimeout();
      _reconnectAttempts = 0;
      _setStatus(ConnectionStatus.connected);
      _startHeartbeat();
      log('✅ Socket connected successfully', name: 'SocketConnection');
    });

    _socket?.onDisconnect((reason) {
      _cancelHeartbeat();
      _setStatus(ConnectionStatus.disconnected);
      log('⚠️ Socket disconnected. Reason: $reason', name: 'SocketConnection');

      if (!_manualDisconnect && !_disposed) {
        _scheduleReconnection();
      }
    });

    _socket?.onConnectError((error) {
      _cancelConnectionTimeout();
      log('❌ Socket connection error: $error', name: 'SocketConnection');
      _handleConnectionError();
    });

    _socket?.onError((error) {
      log('❌ Socket error: $error', name: 'SocketConnection');
      if (!isConnected && !_manualDisconnect && !_disposed) {
        _handleConnectionError();
      }
    });

    _socket?.on('ping', (_) {
      log('🏓 Received ping from server', name: 'SocketConnection');
    });

    _socket?.on('pong', (_) {
      log('🏓 Received pong from server', name: 'SocketConnection');
    });

    // Configurar listeners para todos os eventos
    for (var event in EvoEvents.values) {
      _socket?.on(event.socketEvent, (data) {
        log('📨 Socket event received: ${event.socketEvent}', name: 'SocketConnection');
        final callbacks = _callbacks[event];
        if (callbacks != null) {
          for (var callback in callbacks) {
            try {
              final response = _parseEventData(data, event);
              callback(response);
            } catch (e, stack) {
              log('❌ Error in event callback: $e', name: 'SocketConnection', error: e, stackTrace: stack);
            }
          }
        }
      });
    }
  }

  void _setStatus(ConnectionStatus status) {
    if (_status != status) {
      _status = status;
      log('🔄 Connection status changed to: ${status.name}', name: 'SocketConnection');
    }
  }

  void _startConnectionTimeout() {
    _cancelConnectionTimeout();
    _connectionTimeoutTimer = Timer(Duration(milliseconds: _connectionTimeout), () {
      if (!isConnected) {
        log('⏰ Connection timeout reached', name: 'SocketConnection');
        _handleConnectionError();
      }
    });
  }

  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  void _startHeartbeat() {
    _cancelHeartbeat();
    _heartbeatTimer = Timer.periodic(Duration(milliseconds: _heartbeatInterval), (timer) {
      if (isConnected && !_disposed) {
        try {
          _socket?.emit('ping', DateTime.now().millisecondsSinceEpoch);
          log('🏓 Sent heartbeat ping', name: 'SocketConnection');
        } catch (e) {
          log('❌ Error sending heartbeat: $e', name: 'SocketConnection');
          _handleConnectionError();
        }
      } else {
        _cancelHeartbeat();
      }
    });
  }

  void _cancelHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _handleConnectionError() {
    if (_disposed || _manualDisconnect) return;

    _setStatus(ConnectionStatus.failed);
    _cleanupSocket();
    _scheduleReconnection();
  }

  void _scheduleReconnection() {
    if (_disposed || _manualDisconnect) return;

    _cancelReconnectTimer();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      log('❌ Max reconnection attempts reached. Giving up.', name: 'SocketConnection');
      _setStatus(ConnectionStatus.failed);
      return;
    }

    _reconnectAttempts++;

    // Backoff exponencial com jitter
    final baseDelay = _baseReconnectDelay * (1 << (_reconnectAttempts - 1).clamp(0, 5));
    final jitter = (baseDelay * 0.1 * (DateTime.now().millisecondsSinceEpoch % 100) / 100).round();
    final delay = (baseDelay + jitter).clamp(0, _maxReconnectDelay);

    log('🔄 Scheduling reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delay}ms', name: 'SocketConnection');

    _setStatus(ConnectionStatus.reconnecting);
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (!_disposed && !_manualDisconnect) {
        log('🔄 Attempting reconnection $_reconnectAttempts/$_maxReconnectAttempts', name: 'SocketConnection');
        _attemptConnection();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cleanupSocket() {
    try {
      _socket?.clearListeners();
      _socket?.disconnect();
      _socket?.dispose();
    } catch (e) {
      log('⚠️ Error cleaning up socket: $e', name: 'SocketConnection');
    }
    _socket = null;
  }

  EventResponse _parseEventData(dynamic data, EvoEvents? knownEvent) {
    if (data is Map<String, dynamic>) {
      final event = knownEvent ?? EvoEvents.values.firstWhere((e) => e.socketEvent == data['event'], orElse: () => EvoEvents.UNKNOWN);
      return EventResponse(data: data, event: event);
    } else if (data is String) {
      try {
        final Map<String, dynamic> jsonData = json.decode(data);
        final event = knownEvent ?? EvoEvents.values.firstWhere((e) => e.socketEvent == jsonData['event'], orElse: () => EvoEvents.UNKNOWN);
        return EventResponse(data: jsonData, event: event);
      } catch (e) {
        log('⚠️ Error parsing event data: $e', name: 'SocketConnection');
        return EventResponse(data: {'data': data}, event: EvoEvents.UNKNOWN);
      }
    }
    return EventResponse(data: {'data': data}, event: knownEvent ?? EvoEvents.UNKNOWN);
  }

  void onEvent(EvoEvents event, EventCallback callback) {
    _callbacks[event] ??= [];
    _callbacks[event]!.add(callback);
  }

  void offEvent(EvoEvents event, EventCallback callback) {
    _callbacks[event]?.remove(callback);
  }

  void disconnect() {
    if (_disposed) {
      log('⚠️ Socket connection is already disposed', name: 'SocketConnection');
      return;
    }

    _manualDisconnect = true;
    _setStatus(ConnectionStatus.disconnected);

    try {
      _cancelReconnectTimer();
      _cancelHeartbeat();
      _cancelConnectionTimeout();
      _cleanupSocket();
      _callbacks.clear();
      log('✅ Socket disconnected manually', name: 'SocketConnection');
    } catch (e, stack) {
      log('❌ Error disconnecting socket: $e', name: 'SocketConnection', error: e, stackTrace: stack);
      rethrow;
    }
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    disconnect();
    log('✅ Socket connection disposed', name: 'SocketConnection');
  }

  void emit(String event, dynamic data) {
    if (!isConnected) {
      log('⚠️ Cannot emit event: Socket is not connected', name: 'SocketConnection');
      return;
    }
    try {
      _socket?.emit(event, data);
      log('📤 Event emitted: $event', name: 'SocketConnection');
    } catch (e) {
      log('❌ Error emitting event: $e', name: 'SocketConnection');
    }
  }

  // Método para forçar reconexão manual
  void forceReconnect() {
    if (_disposed) return;

    log('🔄 Forcing reconnection...', name: 'SocketConnection');
    _manualDisconnect = false;
    _reconnectAttempts = 0;

    if (isConnected || isConnecting) {
      _cleanupSocket();
    }

    _attemptConnection();
  }

  // Método para resetar contadores de reconexão
  void resetReconnectionAttempts() {
    _reconnectAttempts = 0;
    log('🔄 Reconnection attempts reset', name: 'SocketConnection');
  }
}
