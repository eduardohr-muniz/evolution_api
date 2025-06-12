import 'dart:convert';
export 'package:evolution_api/src/client/dio_impl/adapter/dio_io.dart' if (dart.library.html) 'package:evolution_api/src/client/dio_impl/adapter/dio_browser.dart';
import 'package:evolution_api/src/client/client_response.dart';
import 'package:evolution_api/src/client/dio_impl/client_exception_dio.dart';
import 'package:evolution_api/src/client/zz_client_export.dart';
import 'package:dio/dio.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';

class ClientDio implements IClient {
  late final Dio _dio;
  bool _enableLogs = false;
  ClientDio({BaseOptions? baseOptions, Talker? talker, bool enableLogs = true}) {
    _enableLogs = enableLogs;

    _dio = DioAdapter(baseOptions ?? _defaultOptions);

    if (_enableLogs) {
      _dio.interceptors.add(
        TalkerDioLogger(talker: talker ?? Talker(), settings: TalkerDioLoggerSettings(enabled: true, printRequestHeaders: true, printRequestData: true, printResponseData: true, printResponseMessage: true, printResponseRedirects: true, printErrorHeaders: true)),
      );
    }
  }

  final _defaultOptions = BaseOptions();

  @override
  IClient auth() {
    _defaultOptions.extra["auth_required"] = true;
    return this;
  }

  @override
  IClient unauth() {
    _defaultOptions.extra["auth_required"] = false;
    return this;
  }

  @override
  Future<ClientResponse<T>> delete<T>(String path, {data, Map<String, dynamic>? query, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: query, options: Options(headers: headers));

      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _trowRestClientException(e);
    }
  }

  @override
  Future<ClientResponse<T>> download<T>(String path, {required String savePath, Map<String, dynamic>? query, Map<String, dynamic>? headers, void Function(int, int)? onReceiveProgress, void Function(double percent)? onReceiveProgressPercent}) async {
    try {
      final response = await _dio.download(
        path,
        savePath,
        onReceiveProgress: (count, total) {
          onReceiveProgress?.call(count, total);
          final double result = (total > 0) ? count / total : 0.1;
          onReceiveProgressPercent?.call(result);
        },
        queryParameters: query,
        options: Options(headers: headers),
      );

      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _trowRestClientException(e);
    }
  }

  @override
  Future<ClientResponse<T>> get<T>(String path, {Map<String, dynamic>? query, Map<String, dynamic>? headers, void Function(int, int)? onReceiveProgress}) async {
    try {
      final response = await _dio.get(path, queryParameters: query, options: Options(headers: headers), onReceiveProgress: onReceiveProgress);

      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _trowRestClientException(e);
    }
  }

  @override
  Future<ClientResponse<T>> patch<T>(String path, {data, Map<String, dynamic>? query, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: query, options: Options(headers: headers));

      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _trowRestClientException(e);
    }
  }

  @override
  Future<ClientResponse<T>> post<T>(String path, {data, Map<String, dynamic>? query, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: query, options: Options(headers: headers, extra: {'mode': 'no-cors'}));

      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _trowRestClientException(e);
    }
  }

  @override
  Future<ClientResponse<T>> put<T>(String path, {data, Map<String, dynamic>? query, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: query, options: Options(headers: headers));
      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _trowRestClientException(e);
    }
  }

  @override
  Future<ClientResponse<T>> request<T>(String path, {data, Map<String, dynamic>? query, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: query, options: Options(headers: headers));

      return _dioResponseConverter(response);
    } on DioException catch (e) {
      return _trowRestClientException(e);
    }
  }

  Future<ClientResponse<T>> _dioResponseConverter<T>(Response<dynamic> response) async {
    return ClientResponse<T>(data: response.data, statusCode: response.statusCode, statusMessage: response.statusMessage);
  }

  String getErrorMessage(DioException dioError) {
    if (dioError.response != null && dioError.response?.data != null && dioError.response?.data is Map) {
      if (dioError.response?.data['error_description'] != null) {
        return dioError.response?.data['error_description'];
      }
      if (dioError.response?.data['error'] != null) {
        return dioError.response?.data['error'];
      }
      if (dioError.response?.data['message'] != null) {
        return dioError.response!.data['message']!.toString();
      }

      if (dioError.response?.data['msg'] != null) {
        return dioError.response?.data['msg'];
      }
    }

    return dioError.toString();
  }

  Never _trowRestClientException(DioException dioError) {
    final exception = ClientException(error: dioError.error, message: getErrorMessage(dioError), response: dioError.response, requestOptions: dioError.requestOptions, stackTrace: dioError.stackTrace, type: dioError.type);

    throw exception;
  }
}
