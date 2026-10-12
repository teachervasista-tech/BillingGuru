import 'dart:io';

import 'package:flutter/material.dart';

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    required this.imagePath,
    this.size = 48,
    this.width,
    this.height,
    super.key,
  });

  final String? imagePath;
  final double size;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Container(
      width: width ?? size,
      height: height ?? size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.image_not_supported_outlined),
                );
              },
            )
          : const Center(child: Icon(Icons.image_outlined)),
    );
  }
}
