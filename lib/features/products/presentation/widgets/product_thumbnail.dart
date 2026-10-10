import 'dart:io';

import 'package:flutter/material.dart';

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({required this.imagePath, this.size = 48, super.key});

  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported_outlined);
              },
            )
          : const Icon(Icons.image_outlined),
    );
  }
}
