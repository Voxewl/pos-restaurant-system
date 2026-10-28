import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DesktopWaiterSalesView extends StatefulWidget {
  const DesktopWaiterSalesView({super.key});

  @override
  State<DesktopWaiterSalesView> createState() => _DesktopWaiterSalesViewState();
}

class _DesktopWaiterSalesViewState extends State<DesktopWaiterSalesView> {
  List<dynamic> _waiterReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWaiterReports();
  }

  Future<void> _fetchWaiterReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await ApiService.fetchWaiterPerformance();
      setState(() {
        _waiterReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading waiter performance: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_waiterReports.isEmpty) {
      return const Center(
        child: Text(
          'No waiter activity recorded for today.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
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
}