import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/checkout_dialog.dart';

class DesktopAdminScreen extends StatefulWidget {
  const DesktopAdminScreen({super.key});

  @override
  State<DesktopAdminScreen> createState() => _DesktopAdminScreenState();
}

class _DesktopAdminScreenState extends State<DesktopAdminScreen> {
  int _selectedNavIndex = 0;
  bool _isLoading = false;

  // Data State
  List<dynamic> _activeTables = [];
  List<dynamic> _waiterReports = [];
  List<dynamic> _printers = [];
  List<dynamic> _categories = [];
  List<dynamic> _menuItems = [];

  // Form Controllers
  final TextEditingController _printerNameCtrl = TextEditingController();
  final TextEditingController _printerIpCtrl = TextEditingController();
  final TextEditingController _printerPortCtrl = TextEditingController(text: '9100');

  final TextEditingController _catNameCtrl = TextEditingController();
  int? _selectedPrinterForCat;

  final TextEditingController _itemNameCtrl = TextEditingController();
  final TextEditingController _itemPriceCtrl = TextEditingController();
  int? _selectedCatForItem;

  @override
  void initState() {
    super.initState();
    _loadCurrentTabData();
  }

  Future<void> _loadCurrentTabData() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedNavIndex == 0) {
        _activeTables = await ApiService.fetchActiveTables();
      } else if (_selectedNavIndex == 1) {
        _waiterReports = await ApiService.fetchWaiterPerformance();
      } else if (_selectedNavIndex == 2) {
        _printers = await ApiService.fetchPrinters();
      } else if (_selectedNavIndex == 3) {
        _categories = await ApiService.fetchCategories();
        _printers = await ApiService.fetchPrinters();
        _menuItems = await ApiService.fetchMenu();
      }
    } catch (e) {
      _showSnackBar('Error loading data: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _openCheckoutModal(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => CheckoutDialog(
        order: order,
        onOrderClosed: _loadCurrentTabData,
      ),
    );
  }

  // --- PRINTER ACTIONS ---
  Future<void> _addPrinter() async {
    final String name = _printerNameCtrl.text.trim();
    final String ip = _printerIpCtrl.text.trim();
    final int port = int.tryParse(_printerPortCtrl.text.trim()) ?? 9100;

    if (name.isEmpty || ip.isEmpty) {
      _showSnackBar('Please fill in Printer Name and IP Address', isError: true);
      return;
    }

    try {
      final success = await ApiService.createPrinter(name, ip, port);
      if (success) {
        _printerNameCtrl.clear();
        _printerIpCtrl.clear();
        _showSnackBar('Printer "$name" added successfully!');
        _loadCurrentTabData();
      }
    } catch (e) {
      _showSnackBar('Failed to add printer: $e', isError: true);
    }
  }

  // --- CATEGORY ACTIONS ---
  Future<void> _addCategory() async {
    final String name = _catNameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter a Category Name', isError: true);
      return;
    }

    try {
      final success = await ApiService.createCategory(name, _selectedPrinterForCat);
      if (success) {
        _catNameCtrl.clear();
        setState(() => _selectedPrinterForCat = null);
        _showSnackBar('Category "$name" added!');
        _loadCurrentTabData();
      }
    } catch (e) {
      _showSnackBar('Failed to add category: $e', isError: true);
    }
  }

  Future<void> _deleteCategory(int catId) async {
    try {
      final success = await ApiService.deleteCategory(catId);
      if (success) {
        _showSnackBar('Category deleted!');
        _loadCurrentTabData();
      }
    } catch (e) {
      _showSnackBar('Failed to delete category: $e', isError: true);
    }
  }

  // --- MENU ITEM ACTIONS ---
  Future<void> _addMenuItem() async {
    final String name = _itemNameCtrl.text.trim();
    final double price = double.tryParse(_itemPriceCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty || price <= 0 || _selectedCatForItem == null) {
      _showSnackBar('Please fill in Item Name, Price, and select a Category', isError: true);
      return;
    }

    try {
      final success = await ApiService.createMenuItem(name, price, _selectedCatForItem!);
      if (success) {
        _itemNameCtrl.clear();
        _itemPriceCtrl.clear();
        setState(() => _selectedCatForItem = null);
        _showSnackBar('Menu Item "$name" added!');
        _loadCurrentTabData();
      }
    } catch (e) {
      _showSnackBar('Failed to add item: $e', isError: true);
    }
  }

  Future<void> _deleteMenuItem(int itemId) async {
    try {
      final success = await ApiService.deleteMenuItem(itemId);
      if (success) {
        _showSnackBar('Menu item deleted!');
        _loadCurrentTabData();
      }
    } catch (e) {
      _showSnackBar('Failed to delete menu item: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR NAVIGATION
          NavigationRail(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedNavIndex = index);
              _loadCurrentTabData();
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF1E293B),
            selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
            unselectedIconTheme: const IconThemeData(color: Colors.white54, size: 24),
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Icon(Icons.point_of_sale, color: Colors.blueAccent, size: 40),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.table_restaurant_outlined),
                selectedIcon: Icon(Icons.table_restaurant),
                label: Text('Active Tables'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge),
                label: Text('Waiter Sales'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.print_outlined),
                selectedIcon: Icon(Icons.print),
                label: Text('Printer Setup'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: Text('Menu & Categories'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // MAIN WORKSPACE
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTabTitle(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 28),
                        onPressed: _loadCurrentTabData,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTabBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTabTitle() {
    switch (_selectedNavIndex) {
      case 0: return 'Active Tables Overview';
      case 1: return 'Waiter Sales & Performance';
      case 2: return 'Thermal Printers Management';
      case 3: return 'Menu & Category Management';
      default: return 'POS Admin';
    }
  }

  Widget _buildTabBody() {
    switch (_selectedNavIndex) {
      case 0: return _buildActiveTablesGrid();
      case 1: return _buildWaiterPerformanceTable();
      case 2: return _buildPrinterSetupView();
      case 3: return _buildMenuAndCategoryView();
      default: return const SizedBox.shrink();
    }
  }

  // TAB 0: ACTIVE TABLES
  Widget _buildActiveTablesGrid() {
    if (_activeTables.isEmpty) {
      return const Center(child: Text('No active tables. All tables are available!'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _activeTables.length,
      itemBuilder: (context, index) {
        final order = _activeTables[index];
        final double total = double.parse((order['total_amount'] ?? order['total'] ?? 0.0).toString());

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order['table_number'] ?? 'Table', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Chip(label: Text('${order['guest_count'] ?? 1} Guests', style: const TextStyle(fontSize: 11))),
                  ],
                ),
                Text('Waiter: ${order['waiter_name'] ?? 'Staff'}', style: const TextStyle(color: Colors.grey)),
                Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => _openCheckoutModal(order),
                    icon: const Icon(Icons.payments, size: 18),
                    label: const Text('CHECKOUT'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 1: WAITER PERFORMANCE
  Widget _buildWaiterPerformanceTable() {
    if (_waiterReports.isEmpty) {
      return const Center(child: Text('No waiter activity recorded for today.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
        columns: const [
          DataColumn(label: Text('Waiter Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Active Tables', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Tables Closed Today', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Total Sales Today', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _waiterReports.map((report) {
          final double sales = double.parse((report['total_sales'] ?? 0.0).toString());
          return DataRow(
            cells: [
              DataCell(Text(report['waiter_name'] ?? 'Unknown')),
              DataCell(Text('${report['active_tables'] ?? 0}')),
              DataCell(Text('${report['tables_closed_today'] ?? 0}')),
              DataCell(Text('\$${sales.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
            ],
          );
        }).toList(),
      ),
    );
  }

  // TAB 2: PRINTER SETUP
  Widget _buildPrinterSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Station Printer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _printerNameCtrl,
                          decoration: const InputDecoration(labelText: 'Printer Name', hintText: 'e.g. Bar Printer', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _printerIpCtrl,
                          decoration: const InputDecoration(labelText: 'Static IP Address', hintText: '127.0.0.1', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _printerPortCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Port', hintText: '9100', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                    onPressed: _addPrinter,
                    child: const Text('Add Printer'),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Active Station Printers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('IP Address')),
                  DataColumn(label: Text('Port')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _printers.map((printer) {
                  return DataRow(cells: [
                    DataCell(Text('${printer['id'] ?? printer['printer_id']}')),
                    DataCell(Text(printer['name'] ?? printer['printer_name'] ?? '')),
                    DataCell(Text(printer['ip_address'] ?? '')),
                    DataCell(Text('${printer['port'] ?? 9100}')),
                    const DataCell(Text('● Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }

  // TAB 3: MENU & CATEGORIES
  Widget _buildMenuAndCategoryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Create Category Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Category & Assign Printer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _catNameCtrl,
                          decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Appetizers', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedPrinterForCat,
                          decoration: const InputDecoration(labelText: 'Target Station Printer', border: OutlineInputBorder()),
                          items: _printers.map<DropdownMenuItem<int>>((printer) {
                            final int id = printer['id'] ?? printer['printer_id'];
                            final String name = printer['name'] ?? printer['printer_name'] ?? 'Printer $id';
                            return DropdownMenuItem<int>(value: id, child: Text(name));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedPrinterForCat = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                    onPressed: _addCategory,
                    child: const Text('Add Category'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Add Menu Item Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Menu Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _itemNameCtrl,
                          decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g. Garlic Bread', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _itemPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price (\$)', hintText: '8.50', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: _selectedCatForItem,
                          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                          items: _categories.map<DropdownMenuItem<int>>((cat) {
                            final int id = cat['id'] ?? cat['category_id'];
                            final String name = cat['name'] ?? cat['category_name'] ?? 'Category $id';
                            return DropdownMenuItem<int>(value: id, child: Text(name));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCatForItem = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                    onPressed: _addMenuItem,
                    child: const Text('Add Item to Menu'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Active Categories Table
          const Text('Active Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Category ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Routed Printer')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _categories.map((cat) {
                  final int catId = cat['id'] ?? cat['category_id'];
                  return DataRow(cells: [
                    DataCell(Text('$catId')),
                    DataCell(Text(cat['name'] ?? cat['category_name'] ?? '')),
                    DataCell(Text(cat['printer_name'] ?? 'Kitchen Printer', style: const TextStyle(color: Colors.blue))),
                    DataCell(
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () => _deleteCategory(catId),
                        child: const Text('Delete Category'),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Current Menu Items Table
          const Text('Current Menu Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Item ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Routed Printer')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _menuItems.map((item) {
                  final int itemId = item['item_id'] ?? item['id'];
                  final double price = double.parse((item['price'] ?? 0.0).toString());
                  return DataRow(cells: [
                    DataCell(Text('$itemId')),
                    DataCell(Text(item['item_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('\$${price.toStringAsFixed(2)}')),
                    DataCell(Text(item['category_name'] ?? '')),
                    DataCell(Text(item['printer_name'] ?? 'Kitchen Printer', style: const TextStyle(color: Colors.blue))),
                    DataCell(
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () => _deleteMenuItem(itemId),
                        child: const Text('Delete Item'),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}