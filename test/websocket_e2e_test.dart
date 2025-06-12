import 'package:evolution_api/src/websocket/socket_connection.dart';
import 'package:evolution_api/src/enums/events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SocketConnection socketConnection;

  setUp(() {
    socketConnection = SocketConnection(
      baseUrl: 'http://localhost:8080',
      instanceName: 'test_instance_e2e',
      apiKey: '429683C4C977415CAAFCCE10F7D57E11',
    );
  });

  tearDown(() {
    socketConnection.disconnect();
  });

  test('Deve conectar com sucesso na localhost', () async {
    bool connected = false;

    socketConnection.onEvent(EvoEvents.CONNECTION_UPDATE, (response) {
      connected = true;
    });

    socketConnection.connect();

    // Aguarda até 5 segundos pela conexão
    await Future.delayed(const Duration(seconds: 5));

    expect(connected, true, reason: 'Socket deveria conectar com sucesso');
  });

  test('Deve desconectar com sucesso', () async {
    bool disconnected = false;

    socketConnection.connect();
    await Future.delayed(const Duration(seconds: 1));
    socketConnection.disconnect();
    await Future.delayed(const Duration(seconds: 1));

    expect(disconnected, true, reason: 'Socket deveria desconectar com sucesso');
  });
}
