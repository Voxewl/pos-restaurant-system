import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../services/api_service.dart';
import '../widgets/dish_card.dart';
import '../widgets/delete_qty_dialog.dart';

class OrderTakingScreen extends StatefulWidget {
  final String tableNumber;
  final int guestCount;
  final String waiterName;

  const OrderTakingScreen({
    super.key,
    required this.tableNumber,
    required this.guestCount,
    required this.waiterName,
  });

  @override
  State<OrderTakingScreen> createState() => _OrderTakingScreenState();
}

class _OrderTakingScreenState extends State<OrderTakingScreen> {
  List<dynamic> _allMenu = [];
  List<dynamic> _categories = [];
  String? _selectedCategory;

  final List<OrderItem> _currentOrder = [];
  bool _isLoadingMenu = true;
  bool _isSubmitting = false;

  String _drawerMode = 'NOTE';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final fetched = await ApiService.fetchMenu();
      final Map<String, dynamic> categoryMap = {};

      for (var item in fetched) {
        if (item['category_name'] != null) {
          categoryMap[item['category_name']] = item['category_id'];
        }
      }

      setState(() {
        _allMenu = fetched;
        _categories = categoryMap.entries.map((e) => {'name': e.key, 'id': e.value}).toList();
        _isLoadingMenu = false;
      });
    } catch (e) {
      setState(() => _isLoadingMenu = false);
    }
  }

  void _addItemToOrder(Map<String, dynamic> item, {String customNote = ''}) {
    final int itemId = item['item_id'] ?? item['id'];
    final String itemName = item['item_name'] ?? item['name'];
    final double price = double.parse(item['price'].toString());

    setState(() {
      final existingIndex = _currentOrder.indexWhere(
            (element) => element.itemId == itemId && element.notes == customNote,
      );
      if (existingIndex >= 0) {
        _currentOrder[existingIndex].quantity += 1;
      } else {
        _currentOrder.add(OrderItem(
          itemId: itemId,
          itemName: itemName,
          price: price,
          quantity: 1,
          notes: customNote,
        ));
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $itemName to order'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  double _calculateTotal() {
    return _currentOrder.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void _openNoteModalForItem(Map<String, dynamic> item, {int? orderIndex}) {
    final String initialNote = orderIndex != null ? _currentOrder[orderIndex].notes : (item['draftNote'] ?? '');
    final TextEditingController controller = TextEditingController(text: initialNote);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Note for ${item['item_name'] ?? item['name'] ?? item['itemName']}'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Insert description here...\n(e.g. No lettuce, extra sauce)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
              onPressed: () {
                setState(() {
                  if (orderIndex != null) {
                    _currentOrder[orderIndex].notes = controller.text;
                  } else {
                    item['draftNote'] = controller.text;
                    _addItemToOrder(item, customNote: controller.text);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Save Note', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openDeleteQuantityModal(int index) {
    final item = _currentOrder[index];
    showDialog(
      context: context,
      builder: (context) => DeleteQtyDialog(
        itemName: item.itemName,
        currentQty: item.quantity,
        onDeleteConfirmed: (qty) {
          setState(() {
            if (qty >= item.quantity) {
              _currentOrder.removeAt(index);
            } else {
              _currentOrder[index].quantity -= qty;
            }
          });
        },
      ),
    );
  }

  Future<void> _submitAndFireOrder() async {
    if (_currentOrder.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final stations = await ApiService.submitOrder(
        tableNumber: widget.tableNumber,
        guestCount: widget.guestCount,
        items: _currentOrder,
        waiterName: widget.waiterName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('${widget.tableNumber} Order sent to $stations station printers!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCategory == null
        ? []
        : _allMenu.where((item) => item['category_name'] == _selectedCategory).toList();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('${widget.tableNumber} (${widget.guestCount} Guests)'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, size: 28),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              if (_currentOrder.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '${_currentOrder.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),

      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          children: [
            Container(
              color: Colors.blue.shade800,
              padding: const EdgeInsets.only(top: 40, bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _drawerMode = 'NOTE'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: _drawerMode == 'NOTE' ? Colors.blue.shade600 : Colors.blue.shade800,
                        child: const Icon(Icons.edit_note, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _drawerMode = 'DELETE'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: _drawerMode == 'DELETE' ? Colors.red.shade600 : Colors.blue.shade800,
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _currentOrder.isEmpty
                  ? const Center(child: Text('No food items selected.'))
                  : ListView.builder(
                itemCount: _currentOrder.length,
                itemBuilder: (context, index) {
                  final item = _currentOrder[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: ListTile(
                      title: Text('${item.quantity}x ${item.itemName}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        item.notes.isNotEmpty ? 'Note: ${item.notes}' : 'Tap icon to edit/manage',
                        style: TextStyle(
                          color: item.notes.isNotEmpty ? Colors.orange.shade900 : Colors.grey,
                          fontWeight: item.notes.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: _drawerMode == 'NOTE'
                          ? IconButton(
                        icon: const Icon(Icons.note_alt_outlined, color: Colors.blue),
                        onPressed: () => _openNoteModalForItem(
                          {'item_name': item.itemName},
                          orderIndex: index,
                        ),
                      )
                          : IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _openDeleteQuantityModal(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: const Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('\$${_calculateTotal().toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isSubmitting ? null : _submitAndFireOrder,
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),

      body: _isLoadingMenu
          ? const Center(child: CircularProgressIndicator())
          : _selectedCategory == null
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return InkWell(
              onTap: () => setState(() => _selectedCategory = cat['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
                  ],
                ),
                child: Center(
                  child: Text(
                    cat['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      )
          : Column(
        children: [
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedCategory = null),
                ),
                Text(
                  'Category: $_selectedCategory',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text('No dishes in this category.'))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return DishCard(
                  item: item,
                  onTap: () => _addItemToOrder(item),
                  onNoteTap: () => _openNoteModalForItem(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}