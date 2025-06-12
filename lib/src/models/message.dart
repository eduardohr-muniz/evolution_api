enum MessageType {
  audioMessage,
  conversation,
  reactionMessage,
  imageMessage,
  documentMessage,
  stickerMessage,
  locationMessage,
  contactMessage,
  unknown;
}

class Message {
  final String id;
  final String remoteJid;
  final String pushName;
  final String content;
  final bool fromMe;
  final String messageType;
  final int messageTimestamp;
  final String instanceId;
  final String source;
  final LocationMessage? locationMessage;
  final String? participant;
  final MessageType messageTypeEnum;

  Message({
    required this.id,
    required this.remoteJid,
    required this.pushName,
    required this.content,
    required this.fromMe,
    required this.messageType,
    required this.messageTimestamp,
    required this.instanceId,
    required this.source,
    this.locationMessage,
    this.participant,
    required this.messageTypeEnum,
  });

  factory Message.fromMap(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    final messageType = MessageType.values.firstWhere((e) => e.name == data['messageType'], orElse: () => MessageType.unknown);

    return Message(
      id: data['key']['id'] ?? '',
      remoteJid: data['key']['remoteJid'],
      participant: data['key']['participant'],
      pushName: data['pushName'] ?? '',
      content: data['message']?['conversation'] ?? '',
      fromMe: data['key']['fromMe'] ?? false,
      messageType: data['messageType'] ?? '',
      messageTimestamp: data['messageTimestamp'] ?? 0,
      instanceId: data['instanceId'] ?? '',
      source: data['source'] ?? '',
      locationMessage: messageType == MessageType.locationMessage ? LocationMessage.fromMap(data['message']['locationMessage']) : null,
      messageTypeEnum: messageType,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, remoteJid: $remoteJid, pushName: $pushName, content: $content, fromMe: $fromMe, messageType: $messageType, messageTimestamp: $messageTimestamp, instanceId: $instanceId, source: $source, locationMessage: $locationMessage, participant: $participant, messageTypeEnum: $messageTypeEnum)';
  }
}

class LocationMessage {
  final double degressLatitude;
  final double degressLongitude;
  final String jpegThumbnail;
  LocationMessage({
    required this.degressLatitude,
    required this.degressLongitude,
    required this.jpegThumbnail,
  });

  factory LocationMessage.fromMap(Map<String, dynamic> map) {
    return LocationMessage(
      degressLatitude: map['degressLatitude']?.toDouble() ?? 0.0,
      degressLongitude: map['degressLongitude']?.toDouble() ?? 0.0,
      jpegThumbnail: map['jpegThumbnail'] ?? '',
    );
  }
}
