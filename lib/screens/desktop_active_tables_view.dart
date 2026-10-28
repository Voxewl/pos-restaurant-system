import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/checkout_dialog.dart';

class DesktopActiveTablesView extends StatefulWidget {
  const DesktopActiveTablesView({super.key});

  @override
  State<DesktopActiveTablesView> createState() => _DesktopActiveTablesViewState();
}

class _DesktopActiveTablesViewState extends State<DesktopActiveTablesView> {
  List<dynamic> _activeTables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveTables();
  }

  Future<void> _fetchActiveTables() async {
    setState(() => _isLoading = true);
    try {
      final tables = await ApiService.fetchActiveTables();
      setState(() {
        _activeTables = tables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading active tables: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openCheckoutModal(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => CheckoutDialog(
        order: order,
        onOrderClosed: _fetchActiveTables,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeTables.isEmpty) {
      return const Center(
        child: Text(
          'No active tables. All tables are available!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
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
                    Text(
                      order['table_number'] ?? 'Table',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Chip(label: Text('${order['guest_count'] ?? 1} Guests', style: const TextStyle(fontSize: 11))),
                  ],
                ),
                Text('Waiter: ${order['waiter_name'] ?? 'Staff'}', style: const TextStyle(color: Colors.grey)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
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
}