import 'package:flutter/material.dart';

class DishCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  final VoidCallback? onNoteTap;

  const DishCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = item['name'] ?? item['item_name'] ?? '';
    final double price = double.tryParse(item['price'].toString()) ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap, // Entire card box acts as the button
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onNoteTap,
                child: const Row(
                  children: [
                    Icon(Icons.edit_note, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'Add description / special note',
                      style: TextStyle(color: Colors.blue, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}