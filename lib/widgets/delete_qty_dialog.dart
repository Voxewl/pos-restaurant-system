import 'package:flutter/material.dart';

class DeleteQtyDialog extends StatefulWidget {
  final String itemName;
  final int currentQty;
  final Function(int) onDeleteConfirmed;

  const DeleteQtyDialog({
    super.key,
    required this.itemName,
    required this.currentQty,
    required this.onDeleteConfirmed,
  });

  @override
  State<DeleteQtyDialog> createState() => _DeleteQtyDialogState();
}

class _DeleteQtyDialogState extends State<DeleteQtyDialog> {
  int deleteQty = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Remove ${widget.itemName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How many do you want to delete?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 32),
                onPressed: deleteQty > 1 ? () => setState(() => deleteQty--) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$deleteQty / ${widget.currentQty}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 32),
                onPressed: deleteQty < widget.currentQty ? () => setState(() => deleteQty++) : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            widget.onDeleteConfirmed(deleteQty);
            Navigator.pop(context);
          },
          child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}