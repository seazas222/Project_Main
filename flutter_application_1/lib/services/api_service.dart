import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/reservation.dart';
import '../models/food.dart';
import '../models/table_model.dart';
import 'current_user_service.dart';

class ApiService {
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return kIsWeb
        ? 'http://localhost:3000/api'
        : 'http://10.0.2.2:3000/api';
  }

  static Map<String, String> get _headers {
    final token = CurrentUserService.instance.user?.authToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
  static Map<String, String> get authHeaders => _headers;

  static Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final userData =
          Map<String, dynamic>.from(data['data']);

      return User.fromJson(userData);
    }

    throw Exception(
      data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ',
    );
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String fullname,
    required String phone,
    required String password,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers,
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

  static Future<User> updateUser({
    required int userId,
    required String username,
    required String fullname,
    String? phone,
    String? email,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'fullname': fullname,
        'phone': phone,
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final userData =
          Map<String, dynamic>.from(data['data']);

      return User.fromJson(userData);
    }

    throw Exception(
      data['message'] ?? 'แก้ไขข้อมูลไม่สำเร็จ',
    );
  }

  static Future<User> updateProfileImage({required int userId, required String imageData}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/profile-image'),
      headers: _headers,
      body: jsonEncode({'image_data': imageData}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return User.fromJson(Map<String, dynamic>.from(data['data']));
    }
    throw Exception(data['message'] ?? 'เปลี่ยนรูปโปรไฟล์ไม่สำเร็จ');
  }

  static Future<List<Reservation>>
      getReservationsByUserId(
    int userId,
  ) => _getReservations(userId);

  static Future<List<Reservation>>
      getCompletedReservationsByUserId(
    int userId,
  ) => _getReservations(userId, historyOnly: true);

  static Future<String> uploadMenuImage(String imageData) async {
    final response = await http.post(Uri.parse('$baseUrl/admin/menu-image'), headers: _headers, body: jsonEncode({'image_data': imageData}));
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return data['data']['menu_image'].toString();
    throw Exception(data['message'] ?? 'อัปโหลดรูปเมนูไม่สำเร็จ');
  }

  static Future<Map<String, dynamic>> getRestaurantBanner() async {
    final response = await http.get(Uri.parse('$baseUrl/restaurant/banner'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data['data'] as Map? ?? {});
    }
    throw Exception(data['message'] ?? 'โหลดรูปหน้าร้านไม่สำเร็จ');
  }

  static String restaurantBannerImageUrl(String filename) =>
      '$baseUrl/restaurant/banner/image?v=${Uri.encodeComponent(filename)}';

  static Future<List<Reservation>> _getReservations(
    int userId, {
    bool historyOnly = false,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/users/$userId/reservations${historyOnly ? '?view=history' : ''}',
      ),
      headers: _headers,
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
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'table_id': tableId,
        'booking_date': bookingDate,
        'dining_date': diningDate,
        'dining_time': diningTime,
        'guests': guests,
        'statusreservation_id':
            statusReservationId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final reservationData =
          Map<String, dynamic>.from(
        data['data'],
      );

      return int.parse(
        reservationData['reservation_id']
            .toString(),
      );
    }

    throw Exception(
      data['errorMessage'] ??
          data['message'] ??
          'ไม่สามารถสร้างรายการจองได้',
    );
  }

  static Future<Reservation> getReservationById(
    int reservationId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/reservations/$reservationId',
      ),
      headers: _headers,
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

  static Future<List<Food>> getMenus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/menu'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final List<dynamic> menus =
          data['data'] ?? [];

      return menus
          .map(
            (item) => Food.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    throw Exception(
      data['message'] ??
          data['errorMessage'] ??
          'ไม่สามารถโหลดรายการอาหารได้',
    );
  }

  static Future<List<RestaurantTable>>
      getTables() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tables'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final List<dynamic> tables =
          data['data'] ?? [];

      return tables
          .map(
            (item) => RestaurantTable.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    throw Exception(
      data['message'] ??
          data['errorMessage'] ??
          'ไม่สามารถโหลดข้อมูลโต๊ะได้',
    );
  }

  static Future<int> createOrder({
    int? reservationId,
    int? tableId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode({
        'reservation_id': reservationId,
        'table_id': tableId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final orderData =
          Map<String, dynamic>.from(
        data['data'],
      );

      return int.parse(
        orderData['order_id'].toString(),
      );
    }

    throw Exception(
      data['message'] ??
          data['errorMessage'] ??
          'ไม่สามารถสร้างออเดอร์ได้',
    );
  }

  static Future<List<RestaurantTable>> getWalkInTables() async {
    final response = await http.get(
      Uri.parse('$baseUrl/walk-in/tables'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data['data'] as List<dynamic>)
          .map((item) => RestaurantTable.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    throw Exception(data['message'] ?? 'โหลดโต๊ะว่างไม่สำเร็จ');
  }

  static Future<int> createOrderDetail({
    required int orderId,
    required int menuId,
    required int quantity,
    required double price,
    int? spicyId,
    int? servingId,
    int? riceId,
    int? eggId,
    String? note,
    List<Map<String, dynamic>> selectedOptions = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/order-details'),
      headers: _headers,
      body: jsonEncode({
        'order_id': orderId,
        'menu_id': menuId,
        'quantity': quantity,
        'price': price,
        'spicy_id': spicyId,
        'serving_id': servingId,
        'rice_id': riceId,
        'egg_id': eggId,
        'note': note,
        'selected_options': selectedOptions,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final detailData =
          Map<String, dynamic>.from(
        data['data'],
      );

      return int.parse(
        detailData['orderdetail_id'].toString(),
      );
    }

    throw Exception(
      data['message'] ??
          data['errorMessage'] ??
          'ไม่สามารถบันทึกรายการอาหารได้',
    );
  }

  static Future<List<Map<String, dynamic>>> getAvailability({
    required String date,
    required String time,
    required int guests,
  }) async {
    final uri = Uri.parse('$baseUrl/availability').replace(
      queryParameters: {'date': date, 'time': time, 'guests': '$guests'},
    );
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data['data'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    throw Exception(data['message'] ?? 'ตรวจสอบโต๊ะว่างไม่สำเร็จ');
  }

  static Future<void> cancelReservation(int reservationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations/$reservationId/cancel'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(data['message'] ?? 'ยกเลิกการจองไม่สำเร็จ');
  }

  static Future<List<Map<String, dynamic>>> getHolidays({
    required String from,
    required String to,
  }) async {
    final uri = Uri.parse('$baseUrl/restaurant/holidays')
        .replace(queryParameters: {'from': from, 'to': to});
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data['data'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    throw Exception(data['message'] ?? 'โหลดวันหยุดไม่สำเร็จ');
  }

  static Future<List<Map<String, dynamic>>> getOrdersByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/orders'),
      headers: _headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data['data'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    throw Exception(data['message'] ?? 'โหลดประวัติออร์เดอร์ไม่สำเร็จ');
  }

  static Future<List<Map<String, dynamic>>> getOrderDetails(int orderId) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/$orderId/details'), headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data['data'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    throw Exception(data['message'] ?? data['errorMessage'] ?? 'โหลดรายละเอียดออร์เดอร์ไม่สำเร็จ');
  }

  static Future<void> updateOrderDetail({
    required int orderId,
    required int detailId,
    required int menuId,
    required int quantity,
    required List<Map<String, dynamic>> selectedOptions,
    String? note,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/details/$detailId'),
      headers: _headers,
      body: jsonEncode({
        'menu_id': menuId,
        'quantity': quantity,
        'selected_options': selectedOptions,
        'note': note,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(data['message'] ?? 'แก้ไขรายละเอียดอาหารไม่สำเร็จ');
  }

  static Future<void> cancelOrder(int orderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/cancel'),
      headers: _headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(data['message'] ?? 'ยกเลิกออร์เดอร์ไม่สำเร็จ');
  }

  static Future<List<Map<String, dynamic>>> getPopularMenus(String month) async {
    final uri = Uri.parse('$baseUrl/stats/popular')
        .replace(queryParameters: {'month': month});
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data['data'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    throw Exception(data['message'] ?? 'โหลดสถิติเมนูไม่สำเร็จ');
  }

  static Future<Map<String, dynamic>> getPaymentQr(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/payment-qr'),
      headers: _headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data['data']);
    }
    throw Exception(data['message'] ?? 'QR ชำระเงินยังไม่พร้อม');
  }

  static Future<void> submitPaymentSlip(int orderId, String imageData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/payment-slip'),
      headers: _headers,
      body: jsonEncode({'image_data': imageData}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(data['message'] ?? 'ส่งสลิปไม่สำเร็จ');
  }

  static Future<Map<String, dynamic>?> getPaymentStatus(int orderId) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/$orderId/payment-status'), headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['data'] == null ? null : Map<String, dynamic>.from(data['data']);
    }
    throw Exception(data['message'] ?? 'ตรวจสอบสถานะชำระเงินไม่สำเร็จ');
  }

  static Future<void> registerPushDevice(String token, String platform) async {
    final response = await http.post(
      Uri.parse('$baseUrl/push-devices'),
      headers: _headers,
      body: jsonEncode({'fcm_token': token, 'platform': platform}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('ลงทะเบียนอุปกรณ์แจ้งเตือนไม่สำเร็จ');
  }

  static Future<bool> getNotificationPreference() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notification-preference'),
      headers: _headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['data']?['enabled'] == true;
    }
    throw Exception(data['message'] ?? 'โหลดการตั้งค่าการแจ้งเตือนไม่สำเร็จ');
  }

  static Future<bool> setNotificationPreference(bool enabled) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notification-preference'),
      headers: _headers,
      body: jsonEncode({'enabled': enabled}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['data']?['enabled'] == true;
    }
    throw Exception(data['message'] ?? 'บันทึกการตั้งค่าการแจ้งเตือนไม่สำเร็จ');
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data['data'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    throw Exception(data['message'] ?? 'โหลดการแจ้งเตือนไม่สำเร็จ');
  }

  static Future<void> markNotificationRead(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('อัปเดตการแจ้งเตือนไม่สำเร็จ');
  }

  static Future<Map<String, dynamic>> adminGet(String path) => _adminRequest('GET', path);
  static Future<Map<String, dynamic>> adminPost(String path, Map<String, dynamic> body) => _adminRequest('POST', path, body);
  static Future<Map<String, dynamic>> adminPut(String path, Map<String, dynamic> body) => _adminRequest('PUT', path, body);
  static Future<Map<String, dynamic>> adminPatch(String path, Map<String, dynamic> body) => _adminRequest('PATCH', path, body);
  static Future<Map<String, dynamic>> adminDelete(String path) => _adminRequest('DELETE', path);

  static Future<Map<String, dynamic>> _adminRequest(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(method, uri)..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw Exception(data['message'] ?? 'คำสั่งสำหรับผู้ดูแลไม่สำเร็จ');
  }
}
