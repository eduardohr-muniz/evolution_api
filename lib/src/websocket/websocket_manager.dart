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

  WebsocketManager({required this.host, required this.token, required this.websocketEnabled, required this.websocketRepository, this.talker});

  bool get isConnected => _socketConnection != null;

  Stream<EventResponse> get events {
    _eventController ??= StreamController<EventResponse>.broadcast();
    return _eventController!.stream;
  }

  Future<Stream<EventResponse>?> connect({required String instanceName}) async {
    if (!websocketEnabled) {
      log('ℹ️ WebSocket is disabled', name: 'Evolution API');
      return null;
    }

    if (_socketConnection != null) {
      log('⚠️ WebSocket is already connected', name: 'Evolution API');
      return events;
    }

    try {
      _socketConnection = SocketConnection(baseUrl: host, instanceName: instanceName, apiKey: token);

      _setupEventListeners();
      _socketConnection!.connect();
      log('✅ WebSocket connected for instance: $instanceName', name: 'Evolution API');
      return events;
    } catch (e, stack) {
      log('❌ Error connecting to WebSocket: $e', name: 'Evolution API', error: e, stackTrace: stack);
      await disconnect();
      rethrow;
    }
  }

  void _setupEventListeners() {
    if (_socketConnection == null) return;

    for (var event in EvoEvents.values) {
      _socketConnection!.onEvent(event, (response) {
        _eventController?.add(response);
      });
    }
  }

  Future<void> disconnect() async {
    if (_socketConnection == null) {
      log('⚠️ WebSocket is not connected', name: 'Evolution API');
      return;
    }

    try {
      _socketConnection!.disconnect();
      _socketConnection = null;
      await _eventController?.close();
      _eventController = null;
      log('✅ WebSocket disconnected', name: 'Evolution API');
    } catch (e, stack) {
      log('❌ Error disconnecting from WebSocket: $e', name: 'Evolution API', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> setEvents({required String instanceName, required List<EvoEvents> events}) async {
    await websocketRepository.setEvents(instanceName: instanceName, events: events);
  }
}
