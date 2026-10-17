import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/order_item.dart';

class ApiService {
  // --- MENU & CATEGORIES ---
  static Future<List<dynamic>> fetchMenu() async {
    final response = await http.get(Uri.parse(ApiConfig.menuUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load menu: ${response.body}');
  }

  static Future<List<dynamic>> fetchCategories() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/categories'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load categories: ${response.body}');
  }

  static Future<bool> createCategory(String name, int? printerId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'printer_id': printerId}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(response.body);
    }
    return true;
  }

  static Future<bool> deleteCategory(int categoryId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/categories/$categoryId'));
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
    return true;
  }

  static Future<bool> createMenuItem(String name, double price, int categoryId, {String description = ''}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/menu'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'item_name': name,
        'name': name,
        'price': price,
        'category_id': categoryId,
        'description': description,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(response.body);
    }
    return true;
  }

  static Future<bool> deleteMenuItem(int itemId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/menu/$itemId'));
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
    return true;
  }

  // --- THERMAL PRINTERS ---
  static Future<List<dynamic>> fetchPrinters() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/printers'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load printers: ${response.body}');
  }

  static Future<bool> createPrinter(String name, String ipAddress, int port) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/printers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'ip_address': ipAddress,
        'port': port,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(response.body);
    }
    return true;
  }

  // --- ORDERS & DASHBOARD ---
  static Future<int> submitOrder({
    required String tableNumber,
    required int guestCount,
    required List<OrderItem> items,
    required String waiterName,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.orderUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'table_number': tableNumber,
        'guest_count': guestCount,
        'items': items.map((e) => e.toJson()).toList(),
        'waiter_name': waiterName,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['stationsNotified'] ?? 1;
    }
    throw Exception('Failed to submit order');
  }

  static Future<List<dynamic>> fetchActiveTables() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/orders/active'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load active tables');
  }

  static Future<List<dynamic>> fetchWaiterPerformance() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/reports/waiters'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load waiter performance');
  }

  static Future<bool> checkoutTable({
    required int orderId,
    required String paymentMethod,
    required double totalAmount,
    required double cashReceived,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'order_id': orderId,
        'payment_method': paymentMethod,
        'total_amount': totalAmount,
        'cash_received': cashReceived,
        'status': 'CLOSED',
      }),
    );
    return response.statusCode == 200;
  }
}