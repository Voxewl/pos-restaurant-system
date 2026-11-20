import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DesktopMenuManagementView extends StatefulWidget {
  const DesktopMenuManagementView({super.key});

  @override
  State<DesktopMenuManagementView> createState() => _DesktopMenuManagementViewState();
}

class _DesktopMenuManagementViewState extends State<DesktopMenuManagementView> {
  bool _isLoading = true;
  List<dynamic> _printers = [];
  List<dynamic> _categories = [];
  List<dynamic> _menuItems = [];

  // Category Controllers
  final TextEditingController _catNameCtrl = TextEditingController();
  int? _selectedPrinterForCat;

  // Menu Item Controllers
  final TextEditingController _itemNameCtrl = TextEditingController();
  final TextEditingController _itemPriceCtrl = TextEditingController();
  final TextEditingController _itemIngredientsCtrl = TextEditingController();
  int? _selectedCatForItem;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  @override
  void dispose() {
    _catNameCtrl.dispose();
    _itemNameCtrl.dispose();
    _itemPriceCtrl.dispose();
    _itemIngredientsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMenuData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await ApiService.fetchCategories();
      final printers = await ApiService.fetchPrinters();
      final menu = await ApiService.fetchMenu();

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _printers = printers;
        _menuItems = menu;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error loading menu data: $e', isError: true);
    }
  }

  Future<void> _addCategory() async {
    final String name = _catNameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter a Category Name', isError: true);
      return;
    }

    try {
      final success = await ApiService.createCategory(name, _selectedPrinterForCat);
      if (success) {
        _catNameCtrl.clear();
        setState(() => _selectedPrinterForCat = null);
        _showSnackBar('Category "$name" added!');
        _loadMenuData();
      }
    } catch (e) {
      _showSnackBar('Failed to add category: $e', isError: true);
    }
  }

  Future<void> _deleteCategory(int catId) async {
    try {
      final success = await ApiService.deleteCategory(catId);
      if (success) {
        _showSnackBar('Category deleted!');
        _loadMenuData();
      }
    } catch (e) {
      _showSnackBar('Failed to delete category: $e', isError: true);
    }
  }

  Future<void> _addMenuItem() async {
    final String name = _itemNameCtrl.text.trim();
    final double price = double.tryParse(_itemPriceCtrl.text.trim()) ?? 0.0;
    final String ingredients = _itemIngredientsCtrl.text.trim();

    if (name.isEmpty || price <= 0 || _selectedCatForItem == null) {
      _showSnackBar('Please fill in Item Name, Price, and select a Category', isError: true);
      return;
    }

    try {
      final success = await ApiService.createMenuItem(
        name,
        price,
        _selectedCatForItem!,
        description: ingredients,
      );
      if (success) {
        _itemNameCtrl.clear();
        _itemPriceCtrl.clear();
        _itemIngredientsCtrl.clear();
        setState(() => _selectedCatForItem = null);
        _showSnackBar('Menu Item "$name" added!');
        _loadMenuData();
      }
    } catch (e) {
      _showSnackBar('Failed to add item: $e', isError: true);
    }
  }

  Future<void> _deleteMenuItem(int itemId) async {
    try {
      final success = await ApiService.deleteMenuItem(itemId);
      if (success) {
        _showSnackBar('Menu item deleted!');
        _loadMenuData();
      }
    } catch (e) {
      _showSnackBar('Failed to delete menu item: $e', isError: true);
    }
  }

  // --- EDIT MENU ITEM & RECIPE BUILDER DIALOG ---
  void _showEditItemDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => _EditMenuItemDialog(
        item: item,
        categories: _categories,
        onSaved: () {
          _loadMenuData();
          _showSnackBar('Dish and recipe updated!');
        },
      ),
    );
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CREATE CATEGORY FORM
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Category & Assign Printer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _catNameCtrl,
                          decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Appetizers', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedPrinterForCat,
                          decoration: const InputDecoration(labelText: 'Target Station Printer', border: OutlineInputBorder()),
                          items: _printers.map<DropdownMenuItem<int>>((printer) {
                            final int id = printer['id'] ?? printer['printer_id'];
                            final String name = printer['name'] ?? printer['printer_name'] ?? 'Printer $id';
                            return DropdownMenuItem<int>(value: id, child: Text(name));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedPrinterForCat = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                    onPressed: _addCategory,
                    child: const Text('Add Category'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. ADD MENU ITEM FORM
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Menu Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _itemNameCtrl,
                          decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g. Garlic Bread', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _itemPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price (\$)', hintText: '8.50', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: _selectedCatForItem,
                          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                          items: _categories.map<DropdownMenuItem<int>>((cat) {
                            final int id = cat['id'] ?? cat['category_id'];
                            final String name = cat['name'] ?? cat['category_name'] ?? 'Category $id';
                            return DropdownMenuItem<int>(value: id, child: Text(name));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCatForItem = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _itemIngredientsCtrl,
                    decoration: const InputDecoration(labelText: 'Ingredients (Optional)', hintText: 'e.g. Bread, Garlic, Butter', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                    onPressed: _addMenuItem,
                    child: const Text('Add Item to Menu'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. ACTIVE CATEGORIES TABLE
          const Text('Active Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Category ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Routed Printer')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _categories.map((cat) {
                  final int catId = cat['id'] ?? cat['category_id'];
                  return DataRow(cells: [
                    DataCell(Text('$catId')),
                    DataCell(Text(cat['name'] ?? cat['category_name'] ?? '')),
                    DataCell(Text(cat['printer_name'] ?? 'Kitchen Printer', style: const TextStyle(color: Colors.blue))),
                    DataCell(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () => _deleteCategory(catId),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. CURRENT MENU ITEMS TABLE
          const Text('Current Menu Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Item ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Routed Printer')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _menuItems.map((item) {
                  final int itemId = item['item_id'] ?? item['id'];
                  final double price = double.tryParse((item['price'] ?? 0.0).toString()) ?? 0.0;
                  return DataRow(cells: [
                    DataCell(Text('$itemId')),
                    DataCell(Text(item['item_name'] ?? item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('\$${price.toStringAsFixed(2)}')),
                    DataCell(Text(item['category_name'] ?? '')),
                    DataCell(Text(item['printer_name'] ?? 'Kitchen Printer', style: const TextStyle(color: Colors.blue))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showEditItemDialog(item),
                            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                            label: const Text('Edit', style: TextStyle(color: Colors.blue)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => _deleteMenuItem(itemId),
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
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

class _EditMenuItemDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<dynamic> categories;
  final VoidCallback onSaved;

  const _EditMenuItemDialog({
    required this.item,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<_EditMenuItemDialog> createState() => _EditMenuItemDialogState();
}

class _EditMenuItemDialogState extends State<_EditMenuItemDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _notesCtrl;
  int? _selectedCategoryId;

  bool _loadingRecipe = true;
  List<dynamic> _inventoryItems = [];
  List<dynamic> _recipeItems = [];

  int? _selectedInventoryId;
  final TextEditingController _qtyCtrl = TextEditingController();

  int get _menuItemId => widget.item['item_id'] ?? widget.item['id'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item['item_name'] ?? widget.item['name']);
    _priceCtrl = TextEditingController(text: widget.item['price'].toString());
    _notesCtrl = TextEditingController(text: widget.item['ingredients'] ?? '');
    _selectedCategoryId = widget.item['category_id'];
    _loadRecipeData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecipeData() async {
    setState(() => _loadingRecipe = true);
    try {
      final inv = await ApiService.fetchInventory();
      final rec = await ApiService.fetchRecipe(_menuItemId);
      if (!mounted) return;
      setState(() {
        _inventoryItems = inv;
        _recipeItems = rec;
        _loadingRecipe = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRecipe = false);
    }
  }

  Future<void> _addIngredientToRecipe() async {
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    if (_selectedInventoryId == null || qty <= 0) return;

    try {
      final ok = await ApiService.addRecipeIngredient(_menuItemId, _selectedInventoryId!, qty);
      if (ok) {
        _qtyCtrl.clear();
        setState(() => _selectedInventoryId = null);
        await _loadRecipeData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding ingredient: $e')));
      }
    }
  }

  Future<void> _removeIngredient(int recipeId) async {
    try {
      final ok = await ApiService.removeRecipeIngredient(recipeId);
      if (ok) {
        await _loadRecipeData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing ingredient: $e')));
      }
    }
  }

  Future<void> _saveDishDetails() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _selectedCategoryId == null) return;
    try {
      await ApiService.updateMenuItem(
        _menuItemId,
        _nameCtrl.text.trim(),
        double.parse(_priceCtrl.text.trim()),
        _selectedCategoryId!,
        ingredients: _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving dish: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Dish & Recipe: ${widget.item['item_name'] ?? widget.item['name']}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DISH DETAILS
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Price (\$)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: widget.categories.map<DropdownMenuItem<int>>((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'] ?? c['category_id'],
                          child: Text(c['name'] ?? c['category_name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kitchen Prep Note (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 28),

              // RECIPE BUILDER SECTION
              const Text(
                'Inventory Recipe (Auto-Deducted on Order)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      value: _selectedInventoryId,
                      decoration: const InputDecoration(
                        labelText: 'Select Inventory Ingredient',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _inventoryItems.map<DropdownMenuItem<int>>((inv) {
                        return DropdownMenuItem<int>(
                          value: inv['id'],
                          child: Text('${inv['name']} (${inv['abbreviation']})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedInventoryId = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Qty Used',
                        hintText: 'e.g. 200',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: _addIngredientToRecipe,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // LINKED INGREDIENTS LIST
              Container(
                height: 170,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _loadingRecipe
                    ? const Center(child: CircularProgressIndicator())
                    : _recipeItems.isEmpty
                    ? Center(
                  child: Text(
                    'No inventory ingredients linked yet.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
                    : ListView.separated(
                  itemCount: _recipeItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final r = _recipeItems[i];
                    return ListTile(
                      dense: true,
                      title: Text(r['ingredient_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${r['quantity_required']} ${r['abbreviation']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _removeIngredient(r['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
          onPressed: _saveDishDetails,
          child: const Text('Save Dish Info'),
        ),
      ],
    );
  }
}