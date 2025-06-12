import 'package:dio/dio.dart';
import 'package:evolution_api/src/client/zz_client_export.dart';
import 'package:evolution_api/src/repositories/instance_repository.dart';
import 'package:evolution_api/src/repositories/send_message_repository.dart';
import 'package:evolution_api/src/repositories/websocket_repository.dart';
import 'package:evolution_api/src/websocket/websocket_manager.dart';
import 'package:talker/talker.dart';
export 'exports.dart';

class EvolutionApi {
  final String host;
  final String token;
  final Talker? talker;
  final bool websocketEnabled;

  EvolutionApi({required this.host, required this.token, this.talker, this.websocketEnabled = false}) {
    _initialize();
  }

  WebsocketManager? _websocket;
  IClient? _client;
  InstanceRepository? _instanceRepository;
  SendMessageRepository? _sendMessageRepository;

  IInstanceRepository get instance => _instanceRepository!;
  ISendMessageRepository get send => _sendMessageRepository!;
  WebsocketManager get websocket => _websocket!;

  Future<void> _initialize() async {
    _client = ClientDio(baseOptions: BaseOptions(baseUrl: host, headers: {'apikey': token}), talker: talker);
    _websocket = WebsocketManager(host: host, token: token, talker: talker, websocketEnabled: websocketEnabled, websocketRepository: WebsocketRepository(client: _client!));
    _instanceRepository = InstanceRepository(client: _client!);
    _sendMessageRepository = SendMessageRepository(client: _client!);
  }
}
