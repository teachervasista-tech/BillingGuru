import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../settings/app_settings_provider.dart';
import '../storage/app_file_storage.dart';
import 'receipt_logo_processor.dart';

export 'receipt_logo_processor.dart' show LogoPrintStyle;

const receiptLogoAssetPath = 'assets/images/receipt_logo.png';

/// Uploaded receipt logo on disk: the original (kept so the print style can
/// be changed without re-uploading) and the print-ready PNG.
class ReceiptLogoStore {
  ReceiptLogoStore({Future<Directory> Function()? root})
    : _root = root ?? AppFileStorage.root;

  final Future<Directory> Function() _root;

  static const originalFile = 'receipt_logo_original';
  static const printFile = 'receipt_logo.png';

  Future<File> _file(String name) async {
    final dir = Directory(
      p.join((await _root()).path, AppFileStorage.brandingFolder),
    );
    if (!dir.existsSync()) await dir.create(recursive: true);
    return File(p.join(dir.path, name));
  }

  /// Converts [bytes] for printing and stores both versions. Throws
  /// `LogoProcessingException` for unreadable images.
  Future<Uint8List> save(Uint8List bytes, LogoPrintStyle style) async {
    final printable = await compute(_process, (bytes, style));
    await (await _file(originalFile)).writeAsBytes(bytes, flush: true);
    await (await _file(printFile)).writeAsBytes(printable, flush: true);
    return printable;
  }

  /// Re-converts the stored original with a different [style].
  Future<Uint8List?> restyle(LogoPrintStyle style) async {
    final original = await _file(originalFile);
    if (!await original.exists()) return null;
    return save(await original.readAsBytes(), style);
  }

  Future<Uint8List?> readPrintable() async {
    final file = await _file(printFile);
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<void> delete() async {
    for (final name in [originalFile, printFile]) {
      final file = await _file(name);
      if (await file.exists()) await file.delete();
    }
  }
}

Uint8List _process((Uint8List, LogoPrintStyle) args) =>
    ReceiptLogoProcessor.process(args.$1, args.$2);

final receiptLogoStoreProvider = Provider<ReceiptLogoStore>(
  (ref) => ReceiptLogoStore(),
);

/// Logo printed on receipts: the uploaded logo, the bundled default, or
/// none — as chosen in Settings → Printer.
final receiptLogoProvider = FutureProvider<Uint8List?>((ref) async {
  final source = ref.watch(
    appSettingsProvider.select((s) => s.receiptLogoSource),
  );
  switch (source) {
    case 'none':
      return null;
    case 'custom':
      try {
        return await ref.watch(receiptLogoStoreProvider).readPrintable();
      } catch (_) {
        return null;
      }
    default:
      try {
        final data = await rootBundle.load(receiptLogoAssetPath);
        return data.buffer.asUint8List();
      } catch (_) {
        return null;
      }
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
