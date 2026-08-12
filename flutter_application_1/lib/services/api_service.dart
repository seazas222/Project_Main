import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/reservation.dart';

class ApiService {
  static const String baseUrl =
      'http://localhost:3000/api';

  // =========================
  // LOGIN
  // =========================

  static Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final userData = Map<String, dynamic>.from(
        data['data'],
      );

      return User.fromJson(userData);
    }

    throw Exception(
      data['message'] ?? 'Login ไม่สำเร็จ',
    );
  }

  // =========================
  // REGISTER
  // =========================

  static Future<Map<String, dynamic>> register({
    required String username,
    required String fullname,
    required String phone,
    required String password,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'fullname': fullname,
        'phone': phone,
        'password': password,
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'สมัครสมาชิกไม่สำเร็จ',
    );
  }

  // =========================
  // UPDATE USER
  // =========================

  static Future<User> updateUser({
    required int userId,
    required String fullname,
    String? phone,
    String? email,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullname': fullname,
        'phone': phone,
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final userData = Map<String, dynamic>.from(
        data['data'],
      );

      return User.fromJson(userData);
    }

    throw Exception(
      data['message'] ?? 'แก้ไขข้อมูลไม่สำเร็จ',
    );
  }

  // =========================
  // GET RESERVATIONS BY USER
  // =========================

  static Future<List<Reservation>>
      getReservationsByUserId(
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/users/$userId/reservations',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final List<dynamic> reservations =
          data['data'] ?? [];

      return reservations
          .map(
            (item) => Reservation.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    throw Exception(
      data['errorMessage'] ??
          data['message'] ??
          'ไม่สามารถโหลดประวัติการจองได้',
    );
  }

    // =========================
  // CREATE RESERVATION
  // =========================

  static Future<int> createReservation({
    required int userId,
    required int tableId,
    required String bookingDate,
    required String diningDate,
    required String diningTime,
    required int guests,
    int statusReservationId = 1,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'table_id': tableId,
        'booking_date': bookingDate,
        'dining_date': diningDate,
        'dining_time': diningTime,
        'guests': guests,
        'statusreservation_id': statusReservationId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final reservationData =
          Map<String, dynamic>.from(data['data']);

      return reservationData['reservation_id'] as int;
    }

    throw Exception(
      data['errorMessage'] ??
          data['message'] ??
          'ไม่สามารถสร้างรายการจองได้',
    );
  }

  // =========================
  // GET RESERVATION BY ID
  // =========================

  static Future<Reservation>
      getReservationById(
    int reservationId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/reservations/$reservationId',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final reservationData =
          Map<String, dynamic>.from(
        data['data'],
      );

      return Reservation.fromJson(
        reservationData,
      );
    }

    throw Exception(
      data['errorMessage'] ??
          data['message'] ??
          'ไม่สามารถโหลดข้อมูลการจองได้',
    );
  }
}