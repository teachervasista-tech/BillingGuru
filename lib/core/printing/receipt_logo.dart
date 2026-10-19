import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const receiptLogoAssetPath = 'assets/images/receipt_logo.png';

/// Loaded once and cached; null when no logo file has been provided.
final receiptLogoProvider = FutureProvider<Uint8List?>((ref) async {
  try {
    final data = await rootBundle.load(receiptLogoAssetPath);
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  }
});

/// On-screen receipt preview: the logo image (if any) above the receipt text.
class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({super.key, required this.receipt, this.logo});

  final String receipt;
  final Uint8List? logo;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (logo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Image.memory(
                  logo!,
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            Text(
              receipt,
              softWrap: false,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontFamilyFallback: ['Courier New', 'Menlo', 'monospace'],
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
