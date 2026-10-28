import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DesktopPrinterSetupView extends StatefulWidget {
  const DesktopPrinterSetupView({super.key});

  @override
  State<DesktopPrinterSetupView> createState() => _DesktopPrinterSetupViewState();
}

class _DesktopPrinterSetupViewState extends State<DesktopPrinterSetupView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _stationNameCtrl = TextEditingController();
  final TextEditingController _winPrinterNameCtrl = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _charsController = TextEditingController(text: '32');

  List<dynamic> _printers = [];
  bool _isLoading = true;

  // Connection & Kitchen Settings State
  String _kitchenMode = 'printer_only'; // 'screen_only', 'screen_and_printer', 'printer_only'
  String _printerType = 'windows';      // 'windows', 'network'
  String _paperSize = '58mm';          // '58mm', '80mm'

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final printers = await ApiService.fetchPrinters();
      final settings = await ApiService.fetchAjustes();

      setState(() {
        _printers = printers;
        if (settings.isNotEmpty) {
          _kitchenMode = settings['modo_cocina'] ?? 'printer_only';
          _printerType = settings['tipo_impresora'] ?? 'windows';
          _winPrinterNameCtrl.text = settings['nombre_impresora_win'] ?? '';
          _ipController.text = settings['ip_impresora'] ?? '';
          _portController.text = settings['puerto_impresora'] ?? '';
          _charsController.text = settings['caracteres_linea'] ?? '32';
          _paperSize = settings['tamano_papel'] ?? '58mm';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading printer settings: $e', isError: true);
    }
  }

  // --- TEST PRINTER CONNECTION ---
  Future<void> _testPrint() async {
    final targetIp = _printerType == 'network'
        ? (_ipController.text.trim().isEmpty ? '127.0.0.1' : _ipController.text.trim())
        : 'USB_WINDOWS';
    final targetPort = int.tryParse(_portController.text.trim()) ?? 9100;
    final winPrinterName = _winPrinterNameCtrl.text.trim();

    try {
      // Auto-persist active connection parameters to server
      await ApiService.saveAjustes({
        'modo_cocina': _kitchenMode,
        'tipo_impresora': _printerType,
        'nombre_impresora_win': winPrinterName,
        'ip_impresora': targetIp,
        'puerto_impresora': targetPort.toString(),
        'caracteres_linea': _charsController.text.trim(),
        'tamano_papel': _paperSize,
      });

      await ApiService.testPrinter({
        'printer_type': _printerType,
        'win_printer_name': winPrinterName,
        'ip_address': targetIp,
        'port': targetPort,
        'name': winPrinterName.isNotEmpty ? winPrinterName : 'Windows USB Test',
      });

      _showSnackBar(_printerType == 'windows'
          ? 'Test job sent to Windows printer: ${winPrinterName.isEmpty ? "Default Printer" : winPrinterName}'
          : 'Test ticket queued for $targetIp:$targetPort');
    } catch (e) {
      _showSnackBar('Test print failed: $e', isError: true);
    }
  }

  // --- ADD NAMED STATION PRINTER ---
  Future<void> _addStationPrinter() async {
    final name = _stationNameCtrl.text.trim();
    final targetIp = _printerType == 'network'
        ? (_ipController.text.trim().isEmpty ? '127.0.0.1' : _ipController.text.trim())
        : (_winPrinterNameCtrl.text.trim().isEmpty ? 'Windows Default' : _winPrinterNameCtrl.text.trim());
    final targetPort = int.tryParse(_portController.text.trim()) ?? 9100;

    if (name.isEmpty) {
      _showSnackBar('Please enter a printer station name (e.g. Kitchen / Bar)', isError: true);
      return;
    }

    try {
      await ApiService.createPrinter(name, targetIp, targetPort);
      _stationNameCtrl.clear();
      _showSnackBar('Station printer "$name" added successfully!');
      _loadAllData();
    } catch (e) {
      _showSnackBar('Failed to add station printer: $e', isError: true);
    }
  }

  Future<void> _deletePrinter(int id, String name) async {
    try {
      await ApiService.deletePrinter(id);
      _showSnackBar('$name removed.');
      _loadAllData();
    } catch (e) {
      _showSnackBar('Error deleting printer: $e', isError: true);
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
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KITCHEN ORDERS MODE
          const Text('Kitchen Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 4),
          const Text('Choose how the kitchen receives new orders.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildOptionCard(
                title: 'Screen Only',
                subtitle: 'Orders arrive on the kitchen display screen only.',
                isSelected: _kitchenMode == 'screen_only',
                onTap: () => setState(() => _kitchenMode = 'screen_only'),
              ),
              const SizedBox(width: 16),
              _buildOptionCard(
                title: 'Screen and Printer',
                subtitle: 'Orders arrive on the screen and a physical ticket is printed.',
                isSelected: _kitchenMode == 'screen_and_printer',
                onTap: () => setState(() => _kitchenMode = 'screen_and_printer'),
              ),
              const SizedBox(width: 16),
              _buildOptionCard(
                title: 'Printer Only',
                subtitle: 'A physical ticket is printed and no screen is used. Staff communicates directly.',
                isSelected: _kitchenMode == 'printer_only',
                onTap: () => setState(() => _kitchenMode = 'printer_only'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 2. PRINTER CONNECTION TYPE
          const Text('Printer Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildOptionCard(
                title: 'Windows Installed',
                subtitle: 'USB or shared printer listed in Windows Printers & Scanners.',
                isSelected: _printerType == 'windows',
                onTap: () => setState(() => _printerType = 'windows'),
              ),
              const SizedBox(width: 16),
              _buildOptionCard(
                title: 'Network (IP)',
                subtitle: 'Ticket printer connected via Ethernet cable or WiFi, usually port 9100.',
                isSelected: _printerType == 'network',
                onTap: () => setState(() => _printerType = 'network'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. PRINTER SETUP & TEST CONNECTION CARD
          Card(
            elevation: 1,
            color: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Windows Printer Driver Input Field
                    if (_printerType == 'windows') ...[
                      TextFormField(
                        controller: _winPrinterNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Windows Printer Name (leave empty for default printer)',
                          hintText: 'e.g. EPSON TM-T20II Receipt',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Network IP & Port Input Fields
                    if (_printerType == 'network') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ipController,
                              decoration: InputDecoration(
                                labelText: 'Printer IP Address',
                                hintText: '192.168.1.151',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 140,
                            child: TextFormField(
                              controller: _portController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Port',
                                hintText: '9100',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Compact Characters per Line Field
                    SizedBox(
                      width: 260,
                      child: TextFormField(
                        controller: _charsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Characters per ticket line',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Paper Width Choice Chips
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('58 mm Paper (32)'),
                          selected: _paperSize == '58mm',
                          selectedColor: const Color(0xFFEDE9FE),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _paperSize == '58mm' ? const Color(0xFF6D28D9) : Colors.black87,
                            fontWeight: _paperSize == '58mm' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _paperSize = '58mm';
                                _charsController.text = '32';
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('80 mm Paper (48)'),
                          selected: _paperSize == '80mm',
                          selectedColor: const Color(0xFFEDE9FE),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _paperSize == '80mm' ? const Color(0xFF6D28D9) : Colors.black87,
                            fontWeight: _paperSize == '80mm' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _paperSize = '80mm';
                                _charsController.text = '48';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If text is cut off or has extra space during the test print, adjust this character count.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Primary Action: Test Printer Connection
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _testPrint,
                      icon: const Icon(Icons.print),
                      label: const Text('Print Test Ticket'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 4. SAVE AS NAMED STATION PRINTER & ACTIVE LIST TABLE
          Card(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Station Printer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stationNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Printer Name (e.g. Kitchen / Bar)',
                            hintText: 'Enter name for current printer setup...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onPressed: _addStationPrinter,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Station'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Active Station Printers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('IP / Driver Name')),
                        DataColumn(label: Text('Port')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _printers.map((printer) {
                        return DataRow(cells: [
                          DataCell(Text('${printer['id']}')),
                          DataCell(Text(printer['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(printer['ip_address'] ?? '')),
                          DataCell(Text('${printer['port'] ?? 9100}')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePrinter(printer['id'], printer['name']),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}