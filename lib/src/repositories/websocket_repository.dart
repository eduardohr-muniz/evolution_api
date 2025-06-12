import 'package:evolution_api/src/client/zz_client_export.dart';
import 'package:evolution_api/src/enums/events.dart';

abstract class IWebsocketRepository {
  Future<List<EvoEvents>> setEvents({required String instanceName, required List<EvoEvents> events});
}

class WebsocketRepository implements IWebsocketRepository {
  final IClient client;

  WebsocketRepository({required this.client});

  @override
  Future<List<EvoEvents>> setEvents({required String instanceName, required List<EvoEvents> events}) async {
    final response = await client.post(
      '/websocket/set/$instanceName',
      data: {
        "websocket": {"enabled": true, "events": events.map((e) => e.name).toList()},
      },
    );

    final List eventsResponse = response.data['events'];
    return eventsResponse.map((e) => EvoEvents.values.byName(e)).toList();
  }
}
