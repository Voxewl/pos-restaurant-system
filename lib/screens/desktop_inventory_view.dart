import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DesktopInventoryView extends StatefulWidget {
  const DesktopInventoryView({super.key});

  @override
  State<DesktopInventoryView> createState() => _DesktopInventoryViewState();
}

class _DesktopInventoryViewState extends State<DesktopInventoryView> {
  bool _isLoading = true;
  List<dynamic> _inventory = [];
  List<dynamic> _units = [];

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  final TextEditingController _alertCtrl = TextEditingController();
  int? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final units = await ApiService.fetchUnits();
      final inventory = await ApiService.fetchInventory();
      setState(() {
        _units = units;
        _inventory = inventory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading inventory: $e', isError: true);
    }
  }

  Future<void> _addInventoryItem() async {
    final name = _nameCtrl.text.trim();
    final stock = double.tryParse(_stockCtrl.text.trim()) ?? 0.0;
    final alert = double.tryParse(_alertCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty || _selectedUnitId == null) {
      _showSnackBar('Please enter a name and select a unit.', isError: true);
      return;
    }

    try {
      final success = await ApiService.createInventoryItem(name, _selectedUnitId!, stock, alert);
      if (success) {
        _nameCtrl.clear();
        _stockCtrl.clear();
        _alertCtrl.clear();
        setState(() => _selectedUnitId = null);
        _showSnackBar('Inventory item added successfully!');
        _loadData();
      }
    } catch (e) {
      _showSnackBar('Failed to add item: $e', isError: true);
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      final success = await ApiService.deleteInventoryItem(id);
      if (success) {
        _showSnackBar('Item deleted.');
        _loadData();
      }
    } catch (e) {
      _showSnackBar('Failed to delete item: $e', isError: true);
    }
  }

  void _showUpdateStockDialog(Map<String, dynamic> item) {
    final stockCtrl = TextEditingController(text: item['current_stock'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Stock: ${item['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${item['current_stock']} ${item['abbreviation']}'),
            const SizedBox(height: 16),
            TextField(
              controller: stockCtrl,
              decoration: const InputDecoration(labelText: 'New Total Stock amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newStock = double.tryParse(stockCtrl.text.trim());
              if (newStock == null) return;
              try {
                await ApiService.updateInventoryStock(item['id'], newStock);
                if (mounted) Navigator.pop(ctx);
                _loadData();
                _showSnackBar('Stock updated!');
              } catch (e) {
                _showSnackBar('Failed to update stock: $e', isError: true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ADD NEW INVENTORY ITEM
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Register New Raw Ingredient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Ingredient Name', hintText: 'e.g. Ground Beef', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          value: _selectedUnitId,
                          decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                          items: _units.map((u) => DropdownMenuItem<int>(
                            value: u['id'],
                            child: Text('${u['name']} (${u['abbreviation']})'),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedUnitId = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Initial Stock', hintText: '0.00', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                    onPressed: _addInventoryItem,
                    child: const Text('Add to Inventory'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. CURRENT INVENTORY TABLE
          const Text('Current Stock Levels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Item Name')),
                  DataColumn(label: Text('Current Stock')),
                  DataColumn(label: Text('Unit')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _inventory.map((item) {
                  final double stock = double.parse(item['current_stock'].toString());
                  final double alert = double.parse(item['min_stock_alert'].toString());
                  final bool isLow = stock <= alert && alert > 0;

                  return DataRow(cells: [
                    DataCell(Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(
                        '$stock',
                        style: TextStyle(
                            color: isLow ? Colors.red : Colors.green.shade700,
                            fontWeight: FontWeight.bold
                        )
                    )),
                    DataCell(Text(item['abbreviation'])),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                            onPressed: () => _showUpdateStockDialog(item),
                            icon: const Icon(Icons.add_box, size: 16),
                            label: const Text('Update Stock'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(item['id']),
                          ),
                        ],
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