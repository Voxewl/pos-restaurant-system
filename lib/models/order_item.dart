class OrderItem {
  final int itemId;
  final String itemName;
  final double price;
  int quantity;
  String notes;

  OrderItem({
    required this.itemId,
    required this.itemName,
    required this.price,
    this.quantity = 1,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'item_name': itemName,
    'price': price,
    'quantity': quantity,
    'notes': notes,
  };
}
