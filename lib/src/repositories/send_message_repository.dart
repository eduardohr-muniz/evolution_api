import 'dart:convert';
import 'dart:typed_data';
import 'package:evolution_api/src/client/zz_client_export.dart';

abstract class ISendMessageRepository {
  Future<void> text({required String instanceName, required String number, required String message});
  Future<void> media({required String instanceName, required Uint8List bytes, required String number, String mediaType = 'image', String? caption});
}

class SendMessageRepository implements ISendMessageRepository {
  final IClient client;
  SendMessageRepository({required this.client});

  @override
  Future<void> text({required String instanceName, required String number, required String message}) async {
    final Map<String, dynamic> data = {'number': number, 'text': message};
    if (message.contains('https')) {
      data['linkPreview'] = true;
    }

    await client.post('/message/sendText/$instanceName', data: data);
  }

  @override
  Future<void> media({required String instanceName, required Uint8List bytes, required String number, String mediaType = 'image', String? caption}) async {
    final base64Media = base64Encode(bytes);

    final data = {'media': base64Media, 'number': number, 'mediatype': mediaType, if (caption != null) 'caption': caption};

    await client.post('/message/sendMedia/$instanceName', data: data);
  }
}
