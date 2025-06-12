import 'package:evolution_api/src/client/dio_impl/client_exception_dio.dart';
import 'package:evolution_api/src/client/zz_client_export.dart';
import 'package:evolution_api/src/enums/connection_state.dart';
import 'package:evolution_api/src/exceptions/instance_not_found.dart';
import 'package:evolution_api/src/responses/create_instance_response.dart';
import 'package:evolution_api/src/responses/instance_connect_response.dart';

abstract interface class IInstanceRepository {
  Future<CreateInstanceResponse> create({required String instanceName, bool qrcode = true, String integration = "WHATSAPP-BAILEYS"});
  Future<InstanceConnectResponse> connect({required String instanceName});
  Future<EvoConnectionStatus> connectionStatus({required String instanceName});
  Future<InstanceConnectResponse> restart({required String instanceName});
  Future<void> logout({required String instanceName});
  Future<void> delete({required String instanceName});
}

class InstanceRepository implements IInstanceRepository {
  final IClient client;
  InstanceRepository({required this.client});

  Future<T> _handleInstanceException<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ClientException catch (e) {
      if (e.message?.toLowerCase().contains('not found') ?? false) {
        throw InstanceNotFound(message: 'Instance not found');
      }
      rethrow;
    }
  }

  @override
  Future<CreateInstanceResponse> create({required String instanceName, bool qrcode = true, String integration = "WHATSAPP-BAILEYS"}) async {
    return _handleInstanceException(() async {
      final response = await client.post('/instance/create', data: {'instanceName': instanceName, 'qrcode': qrcode, 'integration': integration});
      return CreateInstanceResponse.fromMap(response.data);
    });
  }

  @override
  Future<InstanceConnectResponse> connect({required String instanceName}) async {
    return _handleInstanceException(() async {
      final response = await client.get('/instance/connect/$instanceName');
      return InstanceConnectResponse.fromMap(response.data);
    });
  }

  @override
  Future<EvoConnectionStatus> connectionStatus({required String instanceName}) async {
    return _handleInstanceException(() async {
      final response = await client.get('/instance/connectionState/$instanceName');
      return EvoConnectionStatus.values.byName(response.data['instance']['state']);
    });
  }

  @override
  Future<InstanceConnectResponse> restart({required String instanceName}) async {
    return _handleInstanceException(() async {
      final response = await client.post('/instance/restart/$instanceName');
      return InstanceConnectResponse.fromMap(response.data);
    });
  }

  @override
  Future<void> logout({required String instanceName}) async {
    return _handleInstanceException(() async {
      await client.delete('/instance/logout/$instanceName');
    });
  }

  @override
  Future<void> delete({required String instanceName}) async {
    return _handleInstanceException(() async {
      await client.delete('/instance/delete/$instanceName');
    });
  }
}
