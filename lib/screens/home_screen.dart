import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/navigation.dart';

class HomeScreen extends StatefulWidget {
  final String waiterName;
  const HomeScreen({super.key, required this.waiterName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _activeTables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveTables();
  }

  Future<void> _loadActiveTables() async {
    // Only show the loading spinner if we don't have table data yet
    if (_activeTables.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final tables = await ApiService.fetchActiveTables();
      if (mounted) {
        setState(() {
          _activeTables = tables;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showExistingTableSummary(Map<String, dynamic> table) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    List<dynamic> existingItems = [];
    try {
      existingItems = await ApiService.fetchTableItems(table['table_number']);
    } catch (e) {
      // Handle error if fetch fails
    }

    if (!mounted) return;
    AppNavigation.pop(context); // Dismiss loading spinner

    double total = 0.0;
    for (var item in existingItems) {
      final double price = double.tryParse(item['price'].toString()) ?? 0.0;
      final int qty = int.tryParse(item['quantity'].toString()) ?? 1;
      total += price * qty;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                table['table_number'] ?? 'Table',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text('${table['guest_count'] ?? 1} Guests'),
                backgroundColor: Colors.blue.shade100,
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Ordered Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                SizedBox(
                  height: 200,
                  child: existingItems.isEmpty
                      ? const Center(child: Text('No items found for this table.'))
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: existingItems.length,
                    itemBuilder: (context, index) {
                      final item = existingItems[index];
                      final double price = double.tryParse(item['price'].toString()) ?? 0.0;
                      final int qty = item['quantity'] ?? 1;
                      final String notes = item['notes'] ?? '';

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${qty}x ${item['item_name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: notes.isNotEmpty ? Text('Note: $notes', style: const TextStyle(color: Colors.orange)) : null,
                        trailing: Text(
                          '\$${(price * qty).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => AppNavigation.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                AppNavigation.pop(context); // Close modal
                await AppNavigation.goToOrderTaking(
                  context,
                  tableNumber: table['table_number'],
                  guestCount: table['guest_count'] ?? 1,
                  waiterName: widget.waiterName,
                );
                _loadActiveTables();
              },
              child: const Text('Add Items'),
            ),
          ],
        );
      },
    );
  }

  void _openTableDialog() {
    final TextEditingController tableNumController = TextEditingController();
    int guestCount = 2;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Start New Order', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tableNumController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Insert Table Number',
                      hintText: 'e.g. 6',
                      border: const OutlineInputBorder(),
                      errorText: errorMessage,
                    ),
                    onChanged: (value) {
                      final String trimmed = value.trim();
                      if (trimmed.isEmpty) {
                        setDialogState(() => errorMessage = null);
                        return;
                      }

                      final String formattedInput = trimmed.toLowerCase().startsWith('table')
                          ? trimmed
                          : 'Table $trimmed';

                      final bool isOccupied = _activeTables.any((t) {
                        final String activeNum = (t['table_number'] ?? '').toString().trim().toLowerCase();
                        return activeNum == formattedInput.toLowerCase();
                      });

                      setDialogState(() {
                        if (isOccupied) {
                          errorMessage = '$formattedInput is already being used!';
                        } else {
                          errorMessage = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Insert People (Guest Count):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 32),
                        onPressed: guestCount > 1 ? () => setDialogState(() => guestCount--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$guestCount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 32),
                        onPressed: () => setDialogState(() => guestCount++),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => AppNavigation.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (errorMessage != null || tableNumController.text.trim().isEmpty)
                      ? null
                      : () async {
                    final String inputTable = tableNumController.text.trim();
                    final String formattedTable = inputTable.toLowerCase().startsWith('table')
                        ? inputTable
                        : 'Table $inputTable';

                    AppNavigation.pop(context);
                    await AppNavigation.goToOrderTaking(
                      context,
                      tableNumber: formattedTable,
                      guestCount: guestCount,
                      waiterName: widget.waiterName,
                    );
                    _loadActiveTables();
                  },
                  child: const Text('CONTINUE TO MENU'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waiter Terminal (${widget.waiterName})'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveTables,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActiveTables,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: _openTableDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 36, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'OPEN NEW TABLE',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('My Active Tables', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _activeTables.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No open tables right now.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _activeTables.length,
                itemBuilder: (context, index) {
                  final table = _activeTables[index];
                  final double total = double.parse((table['total_amount'] ?? 0.0).toString());

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showExistingTableSummary(table),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              table['table_number'] ?? 'Table',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'Items: ${table['item_count'] ?? 0}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}