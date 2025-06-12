import 'package:evolution_api/src/client/zz_client_export.dart';
import 'package:evolution_api/src/repositories/send_message_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import '../../setup/test_base_options_e2e.dart';

void main() {
  late SendMessageRepository repository;
  late IClient client;
  const instanceName = 'test_instance_e2e';
  const number = '5535991705812';

  setUp(() {
    client = ClientDio(baseOptions: TestBaseOptionsE2e.get);
    repository = SendMessageRepository(client: client);
  });

  group('SendMessageRepository E2E Tests', () {
    test('.sendText() deve enviar messagem de texto', () async {
      await repository.text(instanceName: instanceName, number: number, message: 'Olá teste');
    });
    test('.sendMedia() deve enviar uma imagem com caption', () async {
      // Caminho para um arquivo de imagem de teste
      final bytes = await File('assets/images/image_test.png').readAsBytes();

      await repository.media(instanceName: instanceName, bytes: bytes, number: number, mediaType: 'image', caption: 'Caption teste');
    });

    test('.sendMedia() deve enviar mídia sem caption', () async {
      final filePath = 'assets/images/image_test.png';

      // Verifica se o arquivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        fail('Arquivo de teste não encontrado: $filePath');
      }

      await repository.media(instanceName: instanceName, bytes: file.readAsBytesSync(), number: number, mediaType: 'image');
    });
  });
}
