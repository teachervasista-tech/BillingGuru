import 'package:flutter/material.dart';

Future<bool> showProductDeactivationDialog(
  BuildContext context, {
  required String productName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Deactivate product?'),
        content: Text(
          'The product "$productName" will be removed from '
          'the active Product and PoS lists. Existing sales '
          'history will remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Deactivate'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
