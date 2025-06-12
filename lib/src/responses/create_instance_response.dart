// ignore_for_file: library_private_types_in_public_api

class CreateInstanceResponse {
  final _Instance instance;
  final String hash;
  final _Webhook webhook;
  final _WebSocket websocket;
  final _RabbitMQ rabbitmq;
  final _SQS sqs;
  final _Settings settings;
  final _QRCode qrcode;

  CreateInstanceResponse({
    required this.instance,
    required this.hash,
    required this.webhook,
    required this.websocket,
    required this.rabbitmq,
    required this.sqs,
    required this.settings,
    required this.qrcode,
  });

  factory CreateInstanceResponse.fromMap(Map<String, dynamic> map) {
    return CreateInstanceResponse(
      instance: _Instance.fromMap(map['instance']),
      hash: map['hash'] ?? '',
      webhook: _Webhook.fromMap(map['webhook']),
      websocket: _WebSocket.fromMap(map['websocket']),
      rabbitmq: _RabbitMQ.fromMap(map['rabbitmq']),
      sqs: _SQS.fromMap(map['sqs']),
      settings: _Settings.fromMap(map['settings']),
      qrcode: _QRCode.fromMap(map['qrcode']),
    );
  }

  @override
  String toString() {
    return 'CreateInstanceResponse(instance: $instance, hash: $hash, webhook: $webhook, websocket: $websocket, rabbitmq: $rabbitmq, sqs: $sqs, settings: $settings, qrcode: $qrcode)';
  }
}

class _Instance {
  final String instanceName;
  final String instanceId;
  final String? integration;
  final String? webhookWaBusiness;
  final String accessTokenWaBusiness;
  final String status;

  _Instance({
    required this.instanceName,
    required this.instanceId,
    this.integration,
    this.webhookWaBusiness,
    required this.accessTokenWaBusiness,
    required this.status,
  });

  factory _Instance.fromMap(Map<String, dynamic> map) {
    return _Instance(
      instanceName: map['instanceName'] ?? '',
      instanceId: map['instanceId'] ?? '',
      integration: map['integration'],
      webhookWaBusiness: map['webhookWaBusiness'],
      accessTokenWaBusiness: map['accessTokenWaBusiness'] ?? '',
      status: map['status'] ?? '',
    );
  }
}

class _Webhook {
  _Webhook();

  factory _Webhook.fromMap(Map<String, dynamic> map) {
    return _Webhook();
  }
}

class _WebSocket {
  _WebSocket();

  factory _WebSocket.fromMap(Map<String, dynamic> map) {
    return _WebSocket();
  }
}

class _RabbitMQ {
  _RabbitMQ();

  factory _RabbitMQ.fromMap(Map<String, dynamic> map) {
    return _RabbitMQ();
  }
}

class _SQS {
  _SQS();

  factory _SQS.fromMap(Map<String, dynamic> map) {
    return _SQS();
  }
}

class _Settings {
  final bool rejectCall;
  final String msgCall;
  final bool groupsIgnore;
  final bool alwaysOnline;
  final bool readMessages;
  final bool readStatus;
  final bool syncFullHistory;
  final String wavoipToken;

  _Settings({
    required this.rejectCall,
    required this.msgCall,
    required this.groupsIgnore,
    required this.alwaysOnline,
    required this.readMessages,
    required this.readStatus,
    required this.syncFullHistory,
    required this.wavoipToken,
  });

  factory _Settings.fromMap(Map<String, dynamic> map) {
    return _Settings(
      rejectCall: map['rejectCall'] ?? false,
      msgCall: map['msgCall'] ?? '',
      groupsIgnore: map['groupsIgnore'] ?? false,
      alwaysOnline: map['alwaysOnline'] ?? false,
      readMessages: map['readMessages'] ?? false,
      readStatus: map['readStatus'] ?? false,
      syncFullHistory: map['syncFullHistory'] ?? false,
      wavoipToken: map['wavoipToken'] ?? '',
    );
  }
}

class _QRCode {
  final String? pairingCode;
  final String code;
  final String base64;
  final int count;

  _QRCode({
    this.pairingCode,
    required this.code,
    required this.base64,
    required this.count,
  });

  factory _QRCode.fromMap(Map<String, dynamic> map) {
    return _QRCode(
      pairingCode: map['pairingCode'],
      code: map['code'] ?? '',
      base64: map['base64'] ?? '',
      count: map['count'] ?? 0,
    );
  }
}
