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
    final bool isAvailable = item['is_available'] ?? true;
    final int? maxServings = item['max_servings'] is num
        ? (item['max_servings'] as num).toInt()
        : int.tryParse(item['max_servings']?.toString() ?? '');
    final bool isLowPortions =
        isAvailable && maxServings != null && maxServings > 0 && maxServings <= 3;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: isAvailable ? null : Colors.grey.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isAvailable ? onTap : null, // Blocks tapping when sold out
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                decoration: isAvailable
                                    ? TextDecoration.none
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          if (!isAvailable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else if (isLowPortions) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Only $maxServings left',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.green : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: isAvailable ? onNoteTap : null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 14,
                        color: isAvailable ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAvailable
                            ? 'Add description / special note'
                            : 'Unavailable — out of stock',
                        style: TextStyle(
                          color: isAvailable ? Colors.blue : Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}