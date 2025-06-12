import 'package:evolution_api/src/client/client_response.dart';

abstract class IClient {
  IClient auth();

  IClient unauth();

  Future<ClientResponse<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? query, Map<String, dynamic>? headers});

  Future<ClientResponse<T>> get<T>(String path, {Map<String, dynamic>? query, Map<String, dynamic>? headers, void Function(int, int)? onReceiveProgress});
  Future<ClientResponse<T>> download<T>(String path, {required String savePath, Map<String, dynamic>? query, Map<String, dynamic>? headers, void Function(int, int)? onReceiveProgress});

  Future<ClientResponse<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? query, Map<String, dynamic>? headers});

  Future<ClientResponse<T>> patch<T>(String path, {dynamic data, Map<String, dynamic>? query, Map<String, dynamic>? headers});

  Future<ClientResponse<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? query, Map<String, dynamic>? headers});

  Future<ClientResponse<T>> request<T>(String path, {dynamic data, Map<String, dynamic>? query, Map<String, dynamic>? headers});
}
