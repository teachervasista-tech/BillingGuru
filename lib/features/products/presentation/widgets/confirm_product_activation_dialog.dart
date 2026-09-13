import 'package:flutter/material.dart';

Future<bool> showProductActivationDialog(
  BuildContext context, {
  required String productName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Reactivate product?'),
        content: Text(
          'The product "$productName" will become available '
          'again in the Product and PoS screens.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Reactivate'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
