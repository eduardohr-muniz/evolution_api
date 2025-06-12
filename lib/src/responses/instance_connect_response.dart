import 'package:evolution_api/src/enums/connection_state.dart';

class InstanceConnectResponse {
  final String? code;
  final String? base64;
  final EvoConnectionStatus status;
  InstanceConnectResponse({this.code, this.base64, required this.status});

  factory InstanceConnectResponse.fromMap(Map<String, dynamic> map) {
    final base64 = map['base64'];
    return InstanceConnectResponse(code: map['code'], base64: base64, status: base64 != null ? EvoConnectionStatus.connecting : EvoConnectionStatus.values.byName(map['instance']['state']));
  }

  @override
  String toString() => 'InstanceConnectResponse(code: $code, base64: $base64, status: $status)';
}
