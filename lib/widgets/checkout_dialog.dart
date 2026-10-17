import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CheckoutDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onOrderClosed;

  const CheckoutDialog({
    super.key,
    required this.order,
    required this.onOrderClosed,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  String _paymentMethod = 'CASH';
  final TextEditingController _cashController = TextEditingController();
  double _changeDue = 0.0;
  bool _isProcessing = false;

  void _calculateChange(String value, double total) {
    final double cash = double.tryParse(value) ?? 0.0;
    setState(() {
      _changeDue = cash >= total ? cash - total : 0.0;
    });
  }

  Future<void> _processCheckout(double total) async {
    setState(() => _isProcessing = true);

    final double cashReceived = double.tryParse(_cashController.text) ?? total;

    try {
      final success = await ApiService.checkoutTable(
        orderId: widget.order['order_id'] ?? widget.order['id'],
        paymentMethod: _paymentMethod,
        totalAmount: total,
        cashReceived: cashReceived,
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onOrderClosed();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Table paid & closed successfully! Ticket printed locally.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = double.parse((widget.order['total_amount'] ?? widget.order['total'] ?? 0.0).toString());

    return AlertDialog(
      title: Text('Checkout - ${widget.order['table_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const Divider(height: 24),
            const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('💵 CASH'),
                    selected: _paymentMethod == 'CASH',
                    onSelected: (val) => setState(() => _paymentMethod = 'CASH'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('💳 CARD (Terminal)'),
                    selected: _paymentMethod == 'CARD',
                    onSelected: (val) => setState(() => _paymentMethod = 'CARD'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_paymentMethod == 'CASH') ...[
              TextField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Cash Received (\$)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                onChanged: (val) => _calculateChange(val, total),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change Due:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('\$${_changeDue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade300)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Card Terminal Stub: Payment will auto-approve locally until a physical reader is connected.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: _isProcessing ? null : () => _processCheckout(total),
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('FINALIZE & CLOSE TABLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}