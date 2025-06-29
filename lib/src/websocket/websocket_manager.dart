import 'dart:async';
import 'dart:developer';
import 'package:evolution_api/src/enums/events.dart';
import 'package:evolution_api/src/repositories/websocket_repository.dart';
import 'package:evolution_api/src/responses/event_response.dart';
import 'package:evolution_api/src/websocket/socket_connection.dart';
import 'package:talker/talker.dart';

class WebsocketManager {
  final String host;
  final String token;
  final Talker? talker;
  final bool websocketEnabled;
  final WebsocketRepository websocketRepository;
  SocketConnection? _socketConnection;
  StreamController<EventResponse>? _eventController;
  Timer? _statusMonitorTimer;
  String? _currentInstanceName;

  // Controle de estado
  bool _isDisposed = false;
  bool _isConnecting = false;

  WebsocketManager({required this.host, required this.token, required this.websocketEnabled, required this.websocketRepository, this.talker});

  bool get isConnected => _socketConnection?.isConnected ?? false;
  bool get isConnecting => _isConnecting || (_socketConnection?.isConnecting ?? false);
  ConnectionStatus? get connectionStatus => _socketConnection?.status;
  String? get currentInstanceName => _currentInstanceName;

  Stream<EventResponse> get events {
    _eventController ??= StreamController<EventResponse>.broadcast();
    return _eventController!.stream;
  }

  Future<Stream<EventResponse>?> connect({required String instanceName}) async {
    if (_isDisposed) {
      log('⚠️ WebSocketManager is disposed, cannot connect', name: 'Evolution API');
      return null;
    }

    if (!websocketEnabled) {
      log('ℹ️ WebSocket is disabled', name: 'Evolution API');
      return null;
    }

    if (_socketConnection != null && _currentInstanceName == instanceName) {
      if (isConnected) {
        log('⚠️ WebSocket is already connected to instance: $instanceName', name: 'Evolution API');
        return events;
      }
      if (isConnecting) {
        log('⚠️ WebSocket is already connecting to instance: $instanceName', name: 'Evolution API');
        return events;
      }
    }

    // Se estivermos conectados a uma instância diferente, desconectar primeiro
    if (_socketConnection != null && _currentInstanceName != instanceName) {
      log('🔄 Switching from instance $_currentInstanceName to $instanceName', name: 'Evolution API');
      await _cleanup();
    }

    _currentInstanceName = instanceName;
    _isConnecting = true;

    try {
      _socketConnection = SocketConnection(baseUrl: host, instanceName: instanceName, apiKey: token);

      _setupEventListeners();
      _socketConnection!.connect();
      _startStatusMonitoring();

      log('✅ WebSocket connection initiated for instance: $instanceName', name: 'Evolution API');
      return events;
    } catch (e, stack) {
      log('❌ Error connecting to WebSocket: $e', name: 'Evolution API', error: e, stackTrace: stack);
      _isConnecting = false;
      await _cleanup();
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  void _setupEventListeners() {
    if (_socketConnection == null) return;

    // Listener para todos os eventos
    for (var event in EvoEvents.values) {
      _socketConnection!.onEvent(event, (response) {
        try {
          _eventController?.add(response);

          // Log específico para alguns eventos importantes
          if (event == EvoEvents.CONNECTION_UPDATE || event == EvoEvents.QRCODE_UPDATED || event == EvoEvents.LOGOUT_INSTANCE) {
            log('📨 Important event received: ${event.socketEvent}', name: 'Evolution API');
          }
        } catch (e, stack) {
          log('❌ Error processing event ${event.socketEvent}: $e', name: 'Evolution API', error: e, stackTrace: stack);
        }
      });
    }
  }

  void _startStatusMonitoring() {
    _stopStatusMonitoring();

    _statusMonitorTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      final status = _socketConnection?.status;
      if (status != null) {
        log('📊 Connection status: ${status.name}', name: 'Evolution API');

        // Se a conexão falhou e não é uma desconexão manual, tentar reconectar
        if (status == ConnectionStatus.failed && !_isDisposed) {
          log('🔄 Connection failed, attempting recovery...', name: 'Evolution API');
          _attemptRecovery();
        }
      }
    });
  }

  void _stopStatusMonitoring() {
    _statusMonitorTimer?.cancel();
    _statusMonitorTimer = null;
  }

  void _attemptRecovery() {
    if (_isDisposed || _socketConnection == null || _currentInstanceName == null) {
      return;
    }

    try {
      log('🔧 Attempting connection recovery for instance: $_currentInstanceName', name: 'Evolution API');
      _socketConnection!.forceReconnect();
    } catch (e, stack) {
      log('❌ Error during connection recovery: $e', name: 'Evolution API', error: e, stackTrace: stack);
    }
  }

  Future<void> disconnect() async {
    if (_isDisposed) {
      log('⚠️ WebSocketManager is already disposed', name: 'Evolution API');
      return;
    }

    await _cleanup();
    log('✅ WebSocket disconnected', name: 'Evolution API');
  }

  Future<void> _cleanup() async {
    try {
      _stopStatusMonitoring();

      if (_socketConnection != null) {
        _socketConnection!.disconnect();
        _socketConnection!.dispose();
        _socketConnection = null;
      }

      await _eventController?.close();
      _eventController = null;
      _currentInstanceName = null;
      _isConnecting = false;
    } catch (e, stack) {
      log('❌ Error during cleanup: $e', name: 'Evolution API', error: e, stackTrace: stack);
    }
  }

  Future<void> setEvents({required String instanceName, required List<EvoEvents> events}) async {
    try {
      await websocketRepository.setEvents(instanceName: instanceName, events: events);
      log('✅ Events configured for instance: $instanceName', name: 'Evolution API');
    } catch (e, stack) {
      log('❌ Error setting events: $e', name: 'Evolution API', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // Método para forçar reconexão manual
  Future<void> forceReconnect() async {
    if (_isDisposed) {
      log('⚠️ Cannot force reconnect: WebSocketManager is disposed', name: 'Evolution API');
      return;
    }

    if (_socketConnection == null || _currentInstanceName == null) {
      log('⚠️ Cannot force reconnect: No active connection', name: 'Evolution API');
      return;
    }

    try {
      log('🔄 Force reconnecting to instance: $_currentInstanceName', name: 'Evolution API');
      _socketConnection!.forceReconnect();
    } catch (e, stack) {
      log('❌ Error forcing reconnection: $e', name: 'Evolution API', error: e, stackTrace: stack);

      // Se falhar, tentar uma reconexão completa
      final instanceName = _currentInstanceName!;
      await _cleanup();
      await connect(instanceName: instanceName);
    }
  }

  // Método para resetar tentativas de reconexão
  void resetReconnectionAttempts() {
    if (_socketConnection != null) {
      _socketConnection!.resetReconnectionAttempts();
      log('🔄 Reconnection attempts reset', name: 'Evolution API');
    }
  }

  // Método para verificar se a conexão está saudável
  bool isConnectionHealthy() {
    final status = _socketConnection?.status;
    return status == ConnectionStatus.connected;
  }

  // Método para obter informações detalhadas de status
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': isConnected,
      'isConnecting': isConnecting,
      'status': connectionStatus?.name,
      'instanceName': _currentInstanceName,
      'websocketEnabled': websocketEnabled,
      'isDisposed': _isDisposed,
    };
  }

  // Método para emitir eventos
  void emit(String event, dynamic data) {
    if (!isConnected) {
      log('⚠️ Cannot emit event: WebSocket is not connected', name: 'Evolution API');
      return;
    }

    try {
      _socketConnection?.emit(event, data);
      log('📤 Event emitted: $event', name: 'Evolution API');
    } catch (e, stack) {
      log('❌ Error emitting event: $e', name: 'Evolution API', error: e, stackTrace: stack);
    }
  }

  // Dispose do manager
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    await _cleanup();
    log('✅ WebSocketManager disposed', name: 'Evolution API');
  }
}
