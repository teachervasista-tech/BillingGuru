import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../../../products/presentation/widgets/product_category_pane.dart';
import '../../../products/presentation/widgets/product_search_field.dart';
import '../../../products/presentation/view_models/product_view_model.dart';
import '../../domain/cart_item.dart';
import '../view_models/cart_view_model.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState createState() {
    return _PosScreenState();
  }
}

class _PosScreenState extends ConsumerState<PosScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(productViewModelProvider.notifier)
          .loadProducts(resetFilters: true);
    });
  }

  Future<void> _openBarcodeScanner() async {
    var handling = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              AppBar(
                title: const Text('Scan Barcode'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) async {
                    if (handling) {
                      return;
                    }
                    handling = true;
                    final added = await _onBarcodeDetected(capture);
                    if (added && sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    } else {
                      handling = false;
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _onBarcodeDetected(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue?.trim();

    if (barcode == null || barcode.isEmpty) {
      return false;
    }

    final product = await ref
        .read(productViewModelProvider.notifier)
        .findProductByBarcode(barcode);

    if (!mounted) {
      return false;
    }

    final messenger = ScaffoldMessenger.of(context);

    if (product == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Product not found. Please add the product first, then scan the barcode again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    ref.read(cartProvider.notifier).addProduct(product);

    messenger.showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart.'),
        backgroundColor: Colors.green,
      ),
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          IconButton(
            tooltip: 'Scan barcode',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openBarcodeScanner,
          ),
          IconButton(
            tooltip: 'Sales history',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.go('/sales'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Row(
        children: [
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Row(
              children: [
                const Expanded(flex: 7, child: _ProductsPanel()),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(flex: 3, child: _CartPanel(cart: cart)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CopyrightBanner(),
    );
  }
}

class _ProductsPanel extends ConsumerWidget {
  const _ProductsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productViewModelProvider).asData?.value;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (productState != null) ...[
            ProductCategoryPane(productState: productState),
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Products',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const Expanded(child: ProductSearchField()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.cart});

  final List<CartItem> cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Current Cart',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('The cart is empty'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      return CartItemTile(item: cart[index]);
                    },
                  ),
          ),
          const CartSummary(),
        ],
      ),
    );
  }
}
