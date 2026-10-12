import 'package:billing_guru/core/storage/product_image_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../view_models/product_view_model.dart';
import '../../../../core/ui/app_snackbar.dart';
import 'product_image_picker.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  const ProductFormDialog({super.key, this.product});

  final Product? product;

  bool get isEditing => product != null;

  @override
  ConsumerState<ProductFormDialog> createState() {
    return _ProductFormDialogState();
  }
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _barcodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _taxController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoryController;
  late final TextEditingController _shortCodeController;

  bool _isSaving = false;
  bool _hasAddedProduct = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _imagePath = widget.product?.imagePath;

    _barcodeController = TextEditingController(text: product?.barcode ?? '');

    _nameController = TextEditingController(text: product?.name ?? '');

    _priceController = TextEditingController(
      text: product == null
          ? ''
          : (product.priceCents / 100).toStringAsFixed(2),
    );

    _taxController = TextEditingController(
      text: product?.taxRate.toString() ?? '19',
    );

    _stockController = TextEditingController(
      text: product?.stockQuantity.toString() ?? '',
    );

    _categoryController = TextEditingController(text: product?.category ?? '');
    _shortCodeController = TextEditingController(
      text: product?.shortCode ?? '',
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _shortCodeController.dispose();
    super.dispose();
  }

  bool get _isBlankAddForm {
    return _nameController.text.trim().isEmpty &&
        _categoryController.text.trim().isEmpty &&
        _shortCodeController.text.trim().isEmpty &&
        _barcodeController.text.trim().isEmpty &&
        _priceController.text.trim().isEmpty &&
        _stockController.text.trim().isEmpty &&
        _taxController.text.trim() == '19' &&
        _imagePath == null;
  }

  Future<void> _saveProduct({bool closeAfterSave = false}) async {
    if (closeAfterSave && _hasAddedProduct && _isBlankAddForm) {
      Navigator.of(context).pop(true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final priceCents = _parsePriceToCents(_priceController.text);

    final taxRate = int.parse(_taxController.text.trim());

    final stockQuantity = int.parse(_stockController.text.trim());

    setState(() {
      _isSaving = true;
    });

    final productViewModel = ref.read(productViewModelProvider.notifier);

    final bool success;

    if (widget.product == null) {
      success = await productViewModel.addProduct(
        shortCode: _shortCodeController.text,
        barcode: _barcodeController.text,
        name: _nameController.text,
        category: _categoryController.text,
        priceCents: priceCents,
        taxRate: taxRate,
        stockQuantity: stockQuantity,
        imagePath: _imagePath,
      );
    } else {
      final oldImagePath = widget.product?.imagePath;
      success = await productViewModel.updateProduct(
        product: widget.product!,
        shortCode: _shortCodeController.text,
        barcode: _barcodeController.text,
        name: _nameController.text,
        category: _categoryController.text,
        priceCents: priceCents,
        taxRate: taxRate,
        stockQuantity: stockQuantity,
        imagePath: _imagePath,
      );
      if (success && oldImagePath != null && oldImagePath != _imagePath) {
        await ProductImageStorage.deleteImage(oldImagePath);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (success) {
      if (widget.isEditing) {
        Navigator.of(context).pop(true);
        return;
      }

      if (closeAfterSave) {
        AppSnackbar.success(context, 'Product added successfully.');
        Navigator.of(context).pop(true);
        return;
      }

      _formKey.currentState?.reset();
      _barcodeController.clear();
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      _categoryController.clear();
      _shortCodeController.clear();
      setState(() {
        _hasAddedProduct = true;
        _imagePath = null;
      });
      AppSnackbar.success(context, 'Product added. Add another or close.');
      return;
    }

    final error = ref.read(productViewModelProvider).error;

    AppSnackbar.error(context, error?.toString() ?? 'Unable to save product.');
  }

  int _parsePriceToCents(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final price = double.parse(normalized);
    return (price * 100).round();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _positiveIntegerValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    final parsed = int.tryParse(value.trim());

    if (parsed == null || parsed < 0) {
      return 'Enter a valid non-negative whole number.';
    }

    return null;
  }

  String? _priceValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required.';
    }

    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);

    if (parsed == null || parsed < 0) {
      return 'Enter a valid price.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit product' : 'Add product';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: _requiredValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'Example: Beverages',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: _requiredValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                ProductImagePicker(
                  imagePath: _imagePath,
                  onImageChanged: (imagePath) {
                    setState(() {
                      _imagePath = imagePath;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _shortCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Short code',
                    hintText: 'Example: COF001',
                    prefixIcon: Icon(Icons.code),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    final shortCode = value?.trim() ?? '';

                    if (shortCode.isEmpty) {
                      return 'Short code is required.';
                    }

                    if (shortCode.length > 20) {
                      return 'Short code must be 20 characters or less.';
                    }

                    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(shortCode)) {
                      return 'Use letters, numbers, hyphens, or underscores.';
                    }

                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (optional)',
                    hintText: 'Leave blank if not available',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  validator: (value) {
                    final barcode = value?.trim() ?? '';

                    if (barcode.isEmpty) {
                      return null;
                    }

                    if (barcode.length > 100) {
                      return 'Barcode must be 100 characters or less.';
                    }

                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: 'Example: 2.99',
                    prefixIcon: Icon(Icons.euro),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _priceValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taxController,
                  decoration: const InputDecoration(
                    labelText: 'Tax rate (%)',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _positiveIntegerValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock quantity',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _positiveIntegerValidator,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isSaving) {
                      _saveProduct();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop(_hasAddedProduct);
                },
          child: Text(_hasAddedProduct ? 'Close' : 'Cancel'),
        ),
        if (!widget.isEditing)
          OutlinedButton.icon(
            onPressed: _isSaving
                ? null
                : () => _saveProduct(closeAfterSave: true),
            icon: const Icon(Icons.save),
            label: const Text('Save and close'),
          ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveProduct,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(widget.isEditing ? Icons.save : Icons.add),
          label: Text(widget.isEditing ? 'Update' : 'Add more products'),
        ),
      ],
    );
  }
}
