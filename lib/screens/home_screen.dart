import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'order_taking_screen.dart';

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
    setState(() => _isLoading = true);
    try {
      final tables = await ApiService.fetchActiveTables();
      setState(() {
        // Filter tables assigned to this logged-in waiter (or show all active)
        _activeTables = tables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
                      errorText: errorMessage, // Displays "Table X is already being used"
                    ),
                    onChanged: (value) {
                      final String trimmed = value.trim();
                      if (trimmed.isEmpty) {
                        setDialogState(() => errorMessage = null);
                        return;
                      }

                      // Format input to match table naming format (e.g., "Table 1")
                      final String formattedInput = trimmed.toLowerCase().startsWith('table')
                          ? trimmed
                          : 'Table $trimmed';

                      // Check if formattedInput matches any active table number
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                  // Disable button if input is empty OR if an error message exists
                  onPressed: (errorMessage != null || tableNumController.text.trim().isEmpty)
                      ? null
                      : () async {
                    final String inputTable = tableNumController.text.trim();
                    final String formattedTable = inputTable.toLowerCase().startsWith('table')
                        ? inputTable
                        : 'Table $inputTable';

                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderTakingScreen(
                          tableNumber: formattedTable,
                          guestCount: guestCount,
                          waiterName: widget.waiterName,
                        ),
                      ),
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
              // Open Table Button Row
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
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderTakingScreen(
                              tableNumber: table['table_number'],
                              guestCount: table['guest_count'] ?? 1,
                              waiterName: widget.waiterName,
                            ),
                          ),
                        );
                        _loadActiveTables();
                      },
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