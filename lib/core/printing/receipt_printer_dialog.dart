import 'dart:typed_data';

import 'package:billing_guru/core/currency/currency.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/checkout/domain/sale.dart';
import 'receipt_logo.dart';
import 'receipt_paper_size.dart';
import 'receipt_printer_service.dart';
import 'receipt_template.dart';

typedef PrinterLoader = Future<List<Printer>> Function();

Future<List<Printer>> _listSystemPrinters() => Printing.listPrinters();

/// Resolves to true when the receipt was printed.
Future<bool> showReceiptPrintDialog(
  BuildContext context, {
  required Sale sale,
  required AppCurrency currency,
  required ReceiptTemplate template,
  required String businessDetails,
  Uint8List? logo,
  ReceiptPaperSize paperSize = ReceiptPaperSize.threeInch,
  PrinterLoader printerLoader = _listSystemPrinters,
}) {
  final receipt = ReceiptFormatter.format(
    sale,
    currency,
    template: template,
    businessDetails: businessDetails,
    showLogoPlaceholder: logo == null,
    paperSize: paperSize,
  );

  return showDialog<bool>(
    context: context,
    builder: (context) => _ReceiptPrintDialog(
      title: 'Print receipt (${template.label})',
      receipt: receipt,
      logo: logo,
      paperSize: paperSize,
      printerLoader: printerLoader,
    ),
  ).then((printed) => printed ?? false);
}

class _ReceiptPrintDialog extends StatefulWidget {
  const _ReceiptPrintDialog({
    required this.title,
    required this.receipt,
    required this.logo,
    required this.paperSize,
    required this.printerLoader,
  });

  final String title;
  final String receipt;
  final Uint8List? logo;
  final ReceiptPaperSize paperSize;
  final PrinterLoader printerLoader;

  @override
  State<_ReceiptPrintDialog> createState() => _ReceiptPrintDialogState();
}

class _ReceiptPrintDialogState extends State<_ReceiptPrintDialog> {
  List<Printer> _printers = const [];
  Printer? _selected;
  bool _loading = true;
  bool _printing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    try {
      final printers = await widget.printerLoader();
      if (!mounted) return;
      setState(() {
        _printers = printers;
        _selected =
            printers.where((p) => p.isDefault).firstOrNull ??
            printers.firstOrNull;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to detect printers: $error';
        _loading = false;
      });
    }
  }

  Future<List<int>> _buildPdf(PdfPageFormat format) async {
    final doc = pw.Document();
    final logo = widget.logo;
    pw.MemoryImage? logoImage;
    if (logo != null) {
      try {
        logoImage = pw.MemoryImage(logo);
      } catch (_) {
        logoImage = null;
      }
    }
    // Printer drivers handle a fixed page height better than the unbounded roll format.
    final lines = '\n'.allMatches(widget.receipt).length + 1;
    final height = lines * 11.0 + (logoImage != null ? 76 : 0) + 40;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(widget.paperSize.pageFormat.width, height),
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Image(logoImage, height: 60),
                ),
              ),
            pw.Text(
              widget.receipt,
              style: pw.TextStyle(
                font: pw.Font.courier(),
                fontSize: widget.paperSize.fontSize,
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  Future<void> _print() async {
    final printer = _selected;
    if (printer == null) return;
    setState(() {
      _printing = true;
      _error = null;
    });
    try {
      Future<Uint8List> layout(PdfPageFormat format) async =>
          Uint8List.fromList(await _buildPdf(format));

      var ok = false;
      try {
        // On Windows the plugin never completes the future when the driver
        // rejects the custom paper size, so use the printer's own settings
        // and a timeout instead of waiting forever.
        ok = await Future.value(
          Printing.directPrintPdf(
            printer: printer,
            onLayout: layout,
            name: 'Receipt',
            format: widget.paperSize.pageFormat,
            usePrinterSettings: true,
          ),
        ).timeout(const Duration(seconds: 15));
      } catch (_) {
        ok = false;
      }
      // Fall back to the operating system print dialog if direct printing fails.
      if (!ok) {
        ok = await Printing.layoutPdf(
          onLayout: layout,
          name: 'Receipt',
          format: widget.paperSize.pageFormat,
        );
      }
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _error = 'The receipt was not printed.');
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to print: $error');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading)
              const LinearProgressIndicator()
            else if (_printers.isEmpty)
              const Text('No printers were found on this computer.')
            else
              DropdownButtonFormField<Printer>(
                key: ValueKey(_selected?.url),
                initialValue: _selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Printer',
                  prefixIcon: Icon(Icons.print_outlined),
                ),
                items: [
                  for (final printer in _printers)
                    DropdownMenuItem(
                      value: printer,
                      child: Text(
                        printer.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (printer) => setState(() => _selected = printer),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: ReceiptPreview(receipt: widget.receipt, logo: widget.logo),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: _selected == null || _printing ? null : _print,
          icon: const Icon(Icons.print),
          label: const Text('Print'),
        ),
      ],
    );
  }
}
