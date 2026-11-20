import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/order_item.dart';

class ApiService {
  // Helper to extract backend error messages cleanly
  static String _extractError(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return fallback;
  }

  // --- MENU & CATEGORIES ---
  static Future fetchMenu() async {
    final response = await http.get(Uri.parse(ApiConfig.menuUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load menu: ${response.body}');
  }

  static Future fetchCategories() async {
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
      throw Exception(_extractError(response, 'Failed to create category'));
    }
    return true;
  }

  static Future<bool> deleteCategory(int categoryId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/categories/$categoryId'));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to delete category'));
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
        'ingredients': description,
        'description': description,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to create menu item'));
    }
    return true;
  }

  static Future<bool> updateMenuItem(int itemId, String name, double price, int categoryId, {String ingredients = ''}) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/menu/$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'price': price,
        'category_id': categoryId,
        'ingredients': ingredients,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to update menu item'));
    }
    return true;
  }

  static Future<bool> deleteMenuItem(int itemId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/menu/$itemId'));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to delete menu item'));
    }
    return true;
  }

  // --- THERMAL PRINTERS ---
  static Future fetchPrinters() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/printers'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load printers: ${response.body}');
  }

  static Future getPrinters() async {
    return await fetchPrinters();
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
      throw Exception(_extractError(response, 'Failed to create printer'));
    }
    return true;
  }

  static Future<bool> addPrinter(Map data) async {
    return await createPrinter(data['name'], data['ip_address'], data['port'] ?? 9100);
  }

  static Future<bool> deletePrinter(int printerId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/printers/$printerId'));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to delete printer'));
    }
    return true;
  }

  static Future<bool> testPrinter(Map data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/printers/test'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to test printer'));
    }
    return true;
  }

  // --- AJUSTES / PRINTER & KITCHEN SETTINGS ---
  static Future fetchAjustes() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/ajustes'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load settings: ${response.body}');
  }

  static Future<bool> saveAjustes(Map settings) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/ajustes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(settings),
    );
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to save settings'));
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
    throw Exception(_extractError(response, 'Failed to submit order'));
  }

  static Future fetchActiveTables() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/orders/active'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load active tables');
  }

  // --- WAITER SALES & PERFORMANCE REPORTS ---
  static Future fetchWaiterPerformance() async {
    return await fetchWaiterReports();
  }

  static Future fetchWaiterReports({String period = 'day', String? customDate}) async {
    String url = '${ApiConfig.baseUrl}/reports/waiters?period=$period';
    if (period == 'custom' && customDate != null && customDate.isNotEmpty) {
      url += '&date=$customDate';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load waiter reports');
  }

  static Future fetchWaiterDetails(String waiterName, {String period = 'day', String? customDate}) async {
    String url = '${ApiConfig.baseUrl}/reports/waiters/${Uri.encodeComponent(waiterName)}/details?period=$period';
    if (period == 'custom' && customDate != null && customDate.isNotEmpty) {
      url += '&date=$customDate';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load waiter details');
  }

  static Future fetchTableItems(String tableNumber) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/orders/table/$tableNumber/items'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load table items');
  }

  static Future fetchKdsOrders({String? stationName}) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/kds/orders').replace(
      queryParameters: {
        if (stationName != null && stationName.isNotEmpty) 'station': stationName,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load KDS orders for station: $stationName');
    }
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

  static Future<bool> completeKdsTicket(int orderId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/kds/orders/$orderId/complete-items'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateOrderStatus(int orderId, String status) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/kds/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  // --- INVENTORY MANAGEMENT ---
  static Future<List<dynamic>> fetchUnits() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/units'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load units');
  }

  static Future<List<dynamic>> fetchInventory() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/inventory'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load inventory');
  }

  static Future<bool> createInventoryItem(String name, int unitId, double initialStock, double minAlert) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/inventory'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'unit_id': unitId,
        'current_stock': initialStock,
        'min_stock_alert': minAlert,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to create inventory item'));
    }
    return true;
  }

  static Future<bool> updateInventoryStock(
      int id, {
        required String mode, // 'add' or 'set'
        required double amount,
        String notes = '',
        double? minStockAlert,
      }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/inventory/$id/stock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mode': mode,
        'amount': amount,
        'notes': notes,
        if (minStockAlert != null) 'min_stock_alert': minStockAlert,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to update inventory stock'));
    }
    return true;
  }

  static Future<List<dynamic>> fetchInventoryLogs() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/inventory/logs'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load inventory logs');
  }

  static Future<bool> deleteInventoryItem(int id) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/inventory/$id'));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to delete inventory item'));
    }
    return true;
  }

  // --- DISH RECIPE LINKING ---
  static Future fetchRecipe(int menuItemId) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/menu/$menuItemId/recipe'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load dish recipe');
  }

  static Future<bool> addRecipeIngredient(int menuItemId, int inventoryItemId, double quantityRequired) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/menu/$menuItemId/recipe'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'inventory_item_id': inventoryItemId,
        'quantity_required': quantityRequired,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to add recipe ingredient'));
    }
    return true;
  }

  static Future<bool> removeRecipeIngredient(int recipeId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/recipe/$recipeId'));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Failed to remove recipe ingredient'));
    }
    return true;
  }
}