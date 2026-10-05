import 'package:dio/dio.dart';

Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://absensib1.mobileprojp.com',

      connectTimeout: const Duration(seconds: 10),

      receiveTimeout: const Duration(seconds: 10),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return dio;
}
