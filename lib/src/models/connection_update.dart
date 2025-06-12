import 'package:evolution_api/src/enums/connection_state.dart';

class ConnectionUpdate {
  final String instance;
  final EvoConnectionStatus status;
  final int? statusReason;

  ConnectionUpdate({required this.instance, required this.status, this.statusReason});

  factory ConnectionUpdate.fromMap(Map<String, dynamic> map) {
    return ConnectionUpdate(instance: map['instance'], status: EvoConnectionStatus.values.byName(map['data']['state']), statusReason: map['statusReason'] as int?);
  }

  @override
  String toString() => 'ConnectionUpdate(instance: $instance, status: $status, statusReason: $statusReason)';
}
