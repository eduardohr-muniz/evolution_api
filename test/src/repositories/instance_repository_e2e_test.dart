import 'package:evolution_api/src/client/zz_client_export.dart';
import 'package:evolution_api/src/enums/connection_state.dart';
import 'package:evolution_api/src/repositories/instance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../setup/test_base_options_e2e.dart';

void main() {
  late InstanceRepository repository;
  late IClient client;
  const instanceName = 'test_instance_e2e';

  setUp(() {
    client = ClientDio(baseOptions: TestBaseOptionsE2e.get);
    repository = InstanceRepository(client: client);
  });

  group('InstanceRepository E2E Tests', () {
    test('.createInstance() deve criar uma nova instância', () async {
      final response = await repository.create(instanceName: instanceName, qrcode: true);

      expect(response, isNotNull);
      expect(response.instance.instanceName, equals(instanceName));
    });

    test('instanceConnect() deve trazer o qrcode da instância, se não estiver conectada', () async {
      final response = await repository.connect(instanceName: instanceName);
      expect(response, isNotNull);
      expect(response.base64, isNotNull);
      expect(response.status, EvoConnectionStatus.connecting);
    });

    test('.restart() deve trazer o qrcode da instância, se não estiver conectada, ou a conexão será reiniciada e trara o status como open, caso contrário retornará um erro.', () async {
      final response = await repository.restart(instanceName: instanceName);
      expect(response, isNotNull);
      expect(response.base64, isNotNull);
      expect(response.status, EvoConnectionStatus.connecting);
    });

    test('.connectionStatus() deve verificar o estado da conexão', () async {
      final state = await repository.connectionStatus(instanceName: instanceName);
      expect(state, isNotNull);
      // O estado pode ser um dos valores do enum ConnectionState
      expect(EvoConnectionStatus.values, contains(state));
    });

    test('.logoutInstance() deve fazer logout da instância', () async {
      await repository.logout(instanceName: instanceName);
      // Aguarda um momento para o logout ser processado
      await Future.delayed(const Duration(seconds: 1));
    });

    test('.deleteInstance() deve deletar a instância', () async {
      await repository.delete(instanceName: instanceName);
    });
  });
}
