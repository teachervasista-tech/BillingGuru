import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/storage/product_image_storage.dart';

class ProductImagePicker extends StatefulWidget {
  const ProductImagePicker({
    required this.imagePath,
    required this.onImageChanged,
    super.key,
  });

  final String? imagePath;
  final ValueChanged<String?> onImageChanged;

  @override
  State<ProductImagePicker> createState() {
    return _ProductImagePickerState();
  }
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  bool _isPicking = false;

  Future<void> _pickImage() async {
    if (_isPicking) {
      return;
    }

    setState(() {
      _isPicking = true;
    });

    try {
      final imagePath = await ProductImageStorage.pickAndStoreImage();

      if (!mounted || imagePath == null) {
        return;
      }

      widget.onImageChanged(imagePath);
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    await ProductImageStorage.deleteImage(widget.imagePath);

    widget.onImageChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product image', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                        );
                      },
                    )
                  : const Icon(Icons.image_outlined, size: 36),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: _isPicking ? null : _pickImage,
                  icon: _isPicking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(hasImage ? 'Change image' : 'Choose image'),
                ),
                if (hasImage)
                  TextButton.icon(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove image'),
                  ),
                const SizedBox(height: 4),
                const Text('JPG, PNG, WEBP or BMP'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
