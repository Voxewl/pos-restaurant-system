import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DesktopKdsView extends StatefulWidget {
  final String? initialStation;

  const DesktopKdsView({super.key, this.initialStation});

  @override
  State<DesktopKdsView> createState() => _DesktopKdsViewState();
}

class _DesktopKdsViewState extends State<DesktopKdsView> {
  List<dynamic> _orders = [];
  List<dynamic> _printers = [];
  String _selectedStation = 'All Stations';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialStation != null && widget.initialStation!.isNotEmpty) {
      _selectedStation = widget.initialStation!;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final printers = await ApiService.fetchPrinters();
      setState(() => _printers = printers);
      await _fetchKdsOrders();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchKdsOrders() async {
    try {
      final stationFilter = _selectedStation == 'All Stations' ? '' : _selectedStation;
      final orders = await ApiService.fetchKdsOrders(stationName: stationFilter);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeTicket(int orderId) async {
    try {
      final success = await ApiService.updateOrderStatus(orderId, 'COMPLETED');
      if (success) {
        _fetchKdsOrders(); // Instantly removes the ticket card from the KDS board
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete order'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing order: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP HEADER: Station Selector & Live Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, size: 12, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'KDS Station: $_selectedStation',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ],
              ),
              Row(
                children: [
                  // Station Dropdown Filter
                  DropdownButton<String>(
                    value: _selectedStation,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.tune),
                    items: [
                      const DropdownMenuItem(value: 'All Stations', child: Text('All Stations (Master)')),
                      ..._printers.map<DropdownMenuItem<String>>((printer) {
                        final String name = printer['name'] ?? 'Station ${printer['id']}';
                        return DropdownMenuItem<String>(value: name, child: Text(name));
                      }),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedStation = val);
                        _fetchKdsOrders();
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _fetchKdsOrders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Orders'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // TICKET CARDS FEED
          Expanded(
            child: _orders.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No active orders for $_selectedStation',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 380,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final List items = order['items'] ?? [];
                final int orderId = order['order_id'];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.redAccent, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ticket Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Table ${order['table_number']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'Server: ${order['waiter_name']}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        const Divider(height: 16),

                        // Ticket Items
                        Expanded(
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (ctx, itemIdx) {
                              final item = items[itemIdx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item['quantity']}x ${item['item_name']}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                      Text(
                                        '   * Note: ${item['notes']}',
                                        style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _completeTicket(orderId),
                            child: const Text('Complete Ticket'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}