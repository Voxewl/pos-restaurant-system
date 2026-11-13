import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class DesktopWaiterSalesView extends StatefulWidget {
  const DesktopWaiterSalesView({super.key});

  @override
  State<DesktopWaiterSalesView> createState() => _DesktopWaiterSalesViewState();
}

class _DesktopWaiterSalesViewState extends State<DesktopWaiterSalesView> {
  List<dynamic> _waiters = [];
  bool _isLoading = true;
  String _selectedPeriod = 'day'; // 'day', 'week', 'month', 'year', 'custom'
  DateTime? _customDate;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  String get _formattedCustomDate {
    if (_customDate == null) return '';
    return '${_customDate!.year}-${_customDate!.month.toString().padLeft(2, '0')}-${_customDate!.day.toString().padLeft(2, '0')}';
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case 'week':
        return 'Last 7 Days';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      case 'custom':
        return _formattedCustomDate;
      default:
        return 'Today';
    }
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchWaiterReports(
        period: _selectedPeriod,
        customDate: _formattedCustomDate,
      );
      setState(() {
        _waiters = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sales: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickSpecificDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _customDate = picked;
        _selectedPeriod = 'custom';
      });
      _loadReports();
    }
  }

  Future<void> _exportToExcel() async {
    String url = '${ApiConfig.baseUrl}/reports/waiters/export?period=$_selectedPeriod';
    if (_selectedPeriod == 'custom' && _customDate != null) {
      url += '&date=$_formattedCustomDate';
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication); // Opens browser to download file
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download Excel report.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showWaiterDetailsDialog(String waiterName) {
    showDialog(
      context: context,
      builder: (context) => _WaiterDetailDialog(
        waiterName: waiterName,
        period: _selectedPeriod,
        customDate: _formattedCustomDate,
        periodLabel: _periodLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenue = 0;
    int totalClosed = 0;
    int totalActive = 0;

    for (var w in _waiters) {
      totalRevenue += double.tryParse(w['total_sales'].toString()) ?? 0.0;
      totalClosed += int.tryParse(w['tables_closed'].toString()) ?? 0;
      totalActive += int.tryParse(w['active_tables'].toString()) ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER & FILTER BAR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales & Waiter Performance',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Showing sales data for: $_periodLabel  •  Click any waiter for item breakdown',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildFilterChip('Today', 'day'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Week', 'week'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Month', 'month'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Year', 'year'),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickSpecificDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_selectedPeriod == 'custom' ? _formattedCustomDate : 'Specific Day'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedPeriod == 'custom' ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: _selectedPeriod == 'custom' ? Colors.white : const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // TOP KPI SUMMARY CARDS
          Row(
            children: [
              _buildKpiCard(
                'Total Revenue ($_periodLabel)',
                '\$${totalRevenue.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green.shade700,
                Colors.green.shade50,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                'Tables Closed',
                '$totalClosed',
                Icons.check_circle_outline,
                Colors.blue.shade700,
                Colors.blue.shade50,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                'Currently Active Tables',
                '$totalActive',
                Icons.table_restaurant,
                Colors.orange.shade700,
                Colors.orange.shade50,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // CLEAN WAITER PERFORMANCE TABLE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _waiters.isEmpty
                ? Center(
              child: Text(
                'No sales recorded for $_periodLabel.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
            )
                : Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    dataRowMaxHeight: 64,
                    dataRowMinHeight: 64,
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Waiter Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Active Tables', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tables Closed', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Total Sales', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Details', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _waiters.map((waiter) {
                      final String name = waiter['waiter_name'] ?? 'Staff';
                      final double sales = double.tryParse(waiter['total_sales'].toString()) ?? 0.0;

                      return DataRow(
                        onSelectChanged: (_) => _showWaiterDetailsDialog(name),
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text('${waiter['active_tables']}')),
                          DataCell(Text('${waiter['tables_closed']}')),
                          DataCell(
                            Text(
                              '\$${sales.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: sales > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          DataCell(
                            TextButton.icon(
                              onPressed: () => _showWaiterDetailsDialog(name),
                              icon: const Icon(Icons.bar_chart, size: 18),
                              label: const Text('View Stats'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = value);
          _loadReports();
        }
      },
      selectedColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- MODAL DIALOG FOR INDIVIDUAL WAITER BREAKDOWN ---
class _WaiterDetailDialog extends StatefulWidget {
  final String waiterName;
  final String period;
  final String customDate;
  final String periodLabel;

  const _WaiterDetailDialog({
    required this.waiterName,
    required this.period,
    required this.customDate,
    required this.periodLabel,
  });

  @override
  State<_WaiterDetailDialog> createState() => _WaiterDetailDialogState();
}

class _WaiterDetailDialogState extends State<_WaiterDetailDialog> {
  bool _loading = true;
  Map<String, dynamic>? _details;

  // Local state for the modal's active filters
  late String _currentPeriod;
  late String _currentCustomDate;
  late String _currentPeriodLabel;

  @override
  void initState() {
    super.initState();
    _currentPeriod = widget.period;
    _currentCustomDate = widget.customDate;
    _currentPeriodLabel = widget.periodLabel;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.fetchWaiterDetails(
        widget.waiterName,
        period: _currentPeriod,
        customDate: _currentCustomDate,
      );
      setState(() {
        _details = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _changePeriod(String newPeriod) {
    String label = 'Today';
    if (newPeriod == 'week') label = 'Last 7 Days';
    if (newPeriod == 'month') label = 'This Month';
    if (newPeriod == 'year') label = 'This Year';

    setState(() {
      _currentPeriod = newPeriod;
      _currentPeriodLabel = label;
    });
    _fetchDetails();
  }

  Future<void> _pickSpecificDate() async {
    DateTime initial = DateTime.now();
    if (_currentCustomDate.isNotEmpty) {
      try {
        initial = DateTime.parse(_currentCustomDate);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _currentPeriod = 'custom';
        _currentCustomDate = formatted;
        _currentPeriodLabel = formatted;
      });
      _fetchDetails();
    }
  }

  bool _isDrinkCategory(String category) {
    final lower = category.toLowerCase();
    return lower.contains('drink') ||
        lower.contains('beverage') ||
        lower.contains('cocktail') ||
        lower.contains('bebida') ||
        lower.contains('bar') ||
        lower.contains('coffee') ||
        lower.contains('soda');
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _currentPeriod == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _changePeriod(value);
      },
      selectedColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _details?['summary'] ?? {};
    final List items = _details?['items'] ?? [];

    Map<String, dynamic>? topFood;
    Map<String, dynamic>? topDrink;

    for (var item in items) {
      final cat = item['category_name']?.toString() ?? '';
      if (_isDrinkCategory(cat)) {
        topDrink ??= item;
      } else {
        topFood ??= item;
      }
    }

    final double totalRev = double.tryParse(summary['total_revenue']?.toString() ?? '0') ?? 0.0;
    final double avgTicket = double.tryParse(summary['avg_ticket']?.toString() ?? '0') ?? 0.0;
    final int closedOrders = int.tryParse(summary['closed_orders']?.toString() ?? '0') ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF1E293B),
                      child: Text(
                        widget.waiterName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.waiterName} — Performance Report',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Period: $_currentPeriodLabel',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Inline Modal Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Today', 'day'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Week', 'week'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Month', 'month'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Year', 'year'),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickSpecificDate,
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                      _currentPeriod == 'custom' ? _currentCustomDate : 'Specific Day',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _currentPeriod == 'custom' ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: _currentPeriod == 'custom' ? Colors.white : const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 28),

            // Main Content Area
            _loading
                ? const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()))
                : Column(
              children: [
                // Summary Metrics
                Row(
                  children: [
                    _statBox('Total Sold', '\$${totalRev.toStringAsFixed(2)}', Colors.green.shade700),
                    const SizedBox(width: 12),
                    _statBox('Closed Tables', '$closedOrders', Colors.blue.shade700),
                    const SizedBox(width: 12),
                    _statBox('Avg. Ticket', '\$${avgTicket.toStringAsFixed(2)}', Colors.purple.shade700),
                  ],
                ),
                const SizedBox(height: 20),

                // Top Selling Food & Drink Highlights
                Row(
                  children: [
                    Expanded(
                      child: _highlightCard(
                        icon: Icons.restaurant,
                        iconColor: Colors.orange.shade700,
                        bgColor: Colors.orange.shade50,
                        label: 'Most Sold Food',
                        itemName: topFood != null ? topFood['item_name'] : 'No food sold yet',
                        qty: topFood != null ? '${topFood['total_qty']} sold' : '-',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _highlightCard(
                        icon: Icons.local_bar,
                        iconColor: Colors.teal.shade700,
                        bgColor: Colors.teal.shade50,
                        label: 'Most Sold Drink',
                        itemName: topDrink != null ? topDrink['item_name'] : 'No drinks sold yet',
                        qty: topDrink != null ? '${topDrink['total_qty']} sold' : '-',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Itemized Breakdown List
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('All Items Sold in Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: items.isEmpty
                      ? Center(child: Text('No closed orders in this period.', style: TextStyle(color: Colors.grey.shade500)))
                      : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = items[idx];
                      final rev = double.tryParse(item['item_revenue'].toString()) ?? 0.0;
                      return ListTile(
                        dense: true,
                        title: Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(item['category_name']),
                        trailing: Text(
                          '${item['total_qty']}x   •   \$${rev.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _highlightCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String itemName,
    required String qty,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor)),
                Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(qty, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}