import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
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
  List<dynamic> _logs = [];

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  final TextEditingController _alertCtrl = TextEditingController();
  int? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _stockCtrl.dispose();
    _alertCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final units = await ApiService.fetchUnits();
      final inventory = await ApiService.fetchInventory();
      final logs = await ApiService.fetchInventoryLogs();
      if (!mounted) return;
      setState(() {
        _units = units;
        _inventory = inventory;
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
        _showSnackBar('Inventory item added!');
        _loadData();
      }
    } catch (e) {
      _showSnackBar('Failed to add item: $e', isError: true);
    }
  }

  Future<void> _exportCsv(String endpoint) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showSnackBar('Could not launch CSV download.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
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

  void _showRestockDialog(Map<String, dynamic> item) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final alertCtrl = TextEditingController(text: item['min_stock_alert'].toString());
    String mode = 'add'; // 'add' = Add Delivery, 'set' = Set Exact Stock

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentStock = double.tryParse(item['current_stock'].toString()) ?? 0.0;
          final entered = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
          final previewTotal = mode == 'add' ? (currentStock + entered) : entered;

          return AlertDialog(
            title: Text('Restock / Adjust: ${item['name']}'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Stock: $currentStock ${item['abbreviation']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 14),

                  // Mode Toggle: Add Delivery vs. Set Exact Count
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'add',
                        icon: Icon(Icons.add_circle_outline, size: 18),
                        label: Text('Add Delivery (+)'),
                      ),
                      ButtonSegment(
                        value: 'set',
                        icon: Icon(Icons.edit_note, size: 18),
                        label: Text('Set Exact Count (=)'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (selection) {
                      setDialogState(() => mode = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: amountCtrl,
                          onChanged: (_) => setDialogState(() {}),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: mode == 'add'
                                ? 'Quantity Added (${item['abbreviation']})'
                                : 'New Total Stock (${item['abbreviation']})',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: alertCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Min. Alert',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Restock Note / Supplier (Optional)',
                      hintText: 'e.g. Weekly meat delivery - Inv #104',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
                        const SizedBox(width: 8),
                        Text(
                          'Resulting Stock: ${previewTotal.toStringAsFixed(2)} ${item['abbreviation']}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: () async {
                  final val = double.tryParse(amountCtrl.text.trim());
                  if (val == null || (mode == 'add' && val <= 0)) return;
                  final newAlert = double.tryParse(alertCtrl.text.trim());

                  try {
                    await ApiService.updateInventoryStock(
                      item['id'],
                      mode: mode,
                      amount: val,
                      notes: notesCtrl.text.trim(),
                      minStockAlert: newAlert,
                    );
                    if (mounted) Navigator.pop(ctx);
                    _loadData();
                    _showSnackBar('Stock updated & logged!');
                  } catch (e) {
                    _showSnackBar('Failed to update stock: $e', isError: true);
                  }
                },
                child: const Text('Confirm & Log'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimestamp(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$date $time';
    } catch (_) {
      return raw;
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Identify all low-stock or out-of-stock items
    final lowStockItems = _inventory.where((item) {
      final stock = double.tryParse(item['current_stock'].toString()) ?? 0.0;
      final alert = double.tryParse(item['min_stock_alert'].toString()) ?? 0.0;
      return stock <= 0 || (alert > 0 && stock <= alert);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. VISUAL LOW-STOCK WARNING BANNER
          if (lowStockItems.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Low Stock Alert (${lowStockItems.length} ${lowStockItems.length == 1 ? 'item' : 'items'} need restocking)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade900),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: lowStockItems.map((item) {
                            return Chip(
                              avatar: Icon(Icons.error_outline, size: 16, color: Colors.red.shade800),
                              label: Text(
                                '${item['name']}: ${item['current_stock']} ${item['abbreviation']} left',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade900, fontSize: 12),
                              ),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.red.shade200),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 1. REGISTER NEW RAW INGREDIENT
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
                          decoration: const InputDecoration(
                            labelText: 'Ingredient Name',
                            hintText: 'e.g. Ground Beef',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          value: _selectedUnitId,
                          decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                          items: _units.map<DropdownMenuItem<int>>((u) {
                            return DropdownMenuItem<int>(
                              value: u['id'],
                              child: Text('${u['name']} (${u['abbreviation']})'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedUnitId = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _stockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Initial Stock',
                            hintText: '5000',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _alertCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Low-Stock Alert At',
                            hintText: '1000',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                    onPressed: _addInventoryItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add to Inventory'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. CURRENT STOCK LEVELS HEADER + EXPORT BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Stock Levels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _exportCsv('/inventory/export'),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export Stock CSV'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Ingredient', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Current Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Min. Alert', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _inventory.map((item) {
                  final double stock = double.tryParse(item['current_stock'].toString()) ?? 0.0;
                  final double alert = double.tryParse(item['min_stock_alert'].toString()) ?? 0.0;
                  final bool isOut = stock <= 0;
                  final bool isLow = !isOut && alert > 0 && stock <= alert;

                  Color badgeBg = Colors.green.shade50;
                  Color badgeText = Colors.green.shade800;
                  String statusLabel = 'IN STOCK';

                  if (isOut) {
                    badgeBg = Colors.red.shade100;
                    badgeText = Colors.red.shade900;
                    statusLabel = 'OUT OF STOCK';
                  } else if (isLow) {
                    badgeBg = Colors.orange.shade100;
                    badgeText = Colors.orange.shade900;
                    statusLabel = 'LOW STOCK';
                  }

                  return DataRow(
                    color: (isOut || isLow) ? WidgetStateProperty.all(Colors.red.shade50.withOpacity(0.5)) : null,
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeText),
                          ),
                        ),
                      ),
                      DataCell(Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Text(
                          '$stock ${item['abbreviation']}',
                          style: TextStyle(
                            color: (isOut || isLow) ? Colors.red.shade700 : Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      DataCell(Text(alert > 0 ? '$alert ${item['abbreviation']}' : '—')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (isOut || isLow) ? Colors.red.shade700 : Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showRestockDialog(item),
                              icon: const Icon(Icons.add_box, size: 16),
                              label: const Text('Restock / Adjust'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(item['id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 3. RESTOCK & ADJUSTMENT HISTORY HEADER + EXPORT BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Restock & Adjustment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _exportCsv('/inventory/logs/export'),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export History CSV'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              width: double.infinity,
              child: _logs.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No restock logs recorded yet.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
                  : DataTable(
                columns: const [
                  DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Ingredient', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Change', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Stock Before -> After', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _logs.map((log) {
                  final double change = double.tryParse(log['change_amount'].toString()) ?? 0.0;
                  final bool isPositive = change >= 0;
                  final String abbr = log['abbreviation'] ?? '';

                  return DataRow(cells: [
                    DataCell(Text(_formatTimestamp(log['created_at']?.toString()))),
                    DataCell(Text(log['item_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: log['action_type'] == 'RESTOCK' ? Colors.green.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log['action_type'] ?? 'RESTOCK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: log['action_type'] == 'RESTOCK' ? Colors.green.shade800 : Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${isPositive ? '+' : ''}$change $abbr',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                    DataCell(Text('${log['previous_stock']} $abbr  ->  ${log['new_stock']} $abbr')),
                    DataCell(Text((log['notes'] ?? '').toString().isEmpty ? '—' : log['notes'])),
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