import 'dart:developer';

import 'package:evolution_api/src/enums/events.dart';
import 'package:evolution_api/src/models/connection_update.dart';
import 'package:evolution_api/src/models/message.dart';
import 'package:evolution_api/src/models/qrcode.dart';

class EventResponse {
  final EvoEvents event;
  final dynamic data;

  EventResponse({required this.event, required this.data});

  Message? get message {
    if (data is Map<String, dynamic> && (event == EvoEvents.MESSAGES_UPSERT)) {
      log(data.toString());
      return Message.fromMap(data as Map<String, dynamic>);
    }
    return null;
  }

  ConnectionUpdate? get connectionUpdate {
    if (data is Map<String, dynamic> && event == EvoEvents.CONNECTION_UPDATE) {
      return ConnectionUpdate.fromMap(data as Map<String, dynamic>);
    }
    return null;
  }

  QRCode? get qrcode {
    if (data is Map<String, dynamic> && event == EvoEvents.QRCODE_UPDATED) {
      return QRCode.fromMap(data as Map<String, dynamic>);
    }
    return null;
  }

  bool get isLogout => event == EvoEvents.LOGOUT_INSTANCE;

  @override
  String toString() => 'EventResponse(event: $event, data: $data)';
}
