import 'package:dio/dio.dart';

import 'dio_client.dart';

class ApiServices {
  final Dio dio;

  ApiServices() : dio = createDioClient();

  // =========================
  // LOGIN
  // =========================
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/api/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return response;
  }

  // =========================
  // REGISTER
  // =========================
  Future<Response> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/api/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return response;
  }

  // =========================
  // CHECK IN
  // =========================
  Future<Response> checkIn({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await dio.post(
      '/api/absen/check-in',
      data: {
        'check_in_lat': latitude.toString(),
        'check_in_lng': longitude.toString(),
        'check_in_address': address,
        'status': 'masuk',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    return response;
  }

  // =========================
  // CHECK OUT
  // =========================
  Future<Response> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await dio.post(
      '/api/absen/check-out',
      data: {
        'check_out_lat': latitude.toString(),
        'check_out_lng': longitude.toString(),
        'check_out_location': '$latitude, $longitude',
        'check_out_address': address,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    return response;
  }

  // =========================
  // HISTORY ABSENSI
  // =========================
  Future<Response> getHistory({
    required String token,
    required String start,
    required String end,
  }) async {
    try {
      final response = await dio.get(
        '/api/absen/history',
        queryParameters: {
          'start': start,
          'end': end,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }

      rethrow;
    }
  }

  // =========================
  // PROFILE
  // =========================
  Future<Response> getProfile({
    required String token,
  }) async {
    final response = await dio.get(
      '/api/profile',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    return response;
  }

  // =========================
  // UPDATE PROFILE
  // =========================
  Future<Response> updateProfile({
    required String token,
    required String name,
    required String email,
  }) async {
    final response = await dio.put(
      '/api/profile',
      data: {
        'name': name,
        'email': email,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    return response;
  }

  // =========================
  // DELETE ABSENSI
  // =========================
  Future<Response> deleteAttendance({
    required String token,
    required int id,
  }) async {
    final response = await dio.delete(
      '/api/absen/$id',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    return response;
  }

  // =========================
  // IZIN SAKIT
  // =========================
  Future<Response> izinSakit({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await dio.post(
      '/api/absen/check-in',
      data: {
        'check_in_lat': latitude.toString(),
        'check_in_lng': longitude.toString(),
        'check_in_address': address,
        'status': 'izin',
        'alasan_izin': 'izin sakit',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    return response;
  }
}