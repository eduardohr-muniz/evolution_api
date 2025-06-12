import 'package:evolution_api/src/client/zz_client_export.dart';
import 'package:evolution_api/src/enums/events.dart';
import 'package:evolution_api/src/repositories/websocket_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../setup/test_base_options_e2e.dart';

void main() {
  late IWebsocketRepository repository;
  late IClient client;
  const instanceName = 'test_instance_e2e';

  setUp(() {
    client = ClientDio(baseOptions: TestBaseOptionsE2e.get);
    repository = WebsocketRepository(client: client);
  });

  group('WebsocketRepository E2E Tests', () {
    test('.setEvents() deve setar eventos', () async {
      final events = EvoEvents.values.where((e) => e != EvoEvents.UNKNOWN).toList();
      final response = await repository.setEvents(instanceName: instanceName, events: events);
      expect(response, isA<List<EvoEvents>>());
      expect(response.length, equals(events.length));
      expect(response, equals(events));
    });
  });
}
