import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DesktopMenuManagementView extends StatefulWidget {
  const DesktopMenuManagementView({super.key});

  @override
  State<DesktopMenuManagementView> createState() => _DesktopMenuManagementViewState();
}

class _DesktopMenuManagementViewState extends State<DesktopMenuManagementView> {
  bool _isLoading = true;
  List<dynamic> _printers = [];
  List<dynamic> _categories = [];
  List<dynamic> _menuItems = [];

  final TextEditingController _catNameCtrl = TextEditingController();
  int? _selectedPrinterForCat;

  final TextEditingController _itemNameCtrl = TextEditingController();
  final TextEditingController _itemPriceCtrl = TextEditingController();
  int? _selectedCatForItem;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await ApiService.fetchCategories();
      final printers = await ApiService.fetchPrinters();
      final menu = await ApiService.fetchMenu();

      setState(() {
        _categories = categories;
        _printers = printers;
        _menuItems = menu;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading menu data: $e', isError: true);
    }
  }

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
        _loadMenuData();
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
        _loadMenuData();
      }
    } catch (e) {
      _showSnackBar('Failed to delete category: $e', isError: true);
    }
  }

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
        _loadMenuData();
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
        _loadMenuData();
      }
    } catch (e) {
      _showSnackBar('Failed to delete menu item: $e', isError: true);
    }
  }

  void _showSnackBar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CREATE CATEGORY FORM
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

          // 2. ADD MENU ITEM FORM
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

          // 3. ACTIVE CATEGORIES TABLE
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

          // 4. CURRENT MENU ITEMS TABLE
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