import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/section_card.dart';
import '../../../../core/printing/receipt_logo.dart';
import '../../../../core/printing/receipt_logo_processor.dart';
import '../../../../core/settings/app_settings_provider.dart';

/// Settings → Printer: upload the logo printed at the top of receipts. The
/// upload is converted to a print-ready black-and-white (or grayscale) image.
class ReceiptLogoCard extends ConsumerStatefulWidget {
  const ReceiptLogoCard({super.key});

  @override
  ConsumerState<ReceiptLogoCard> createState() => _ReceiptLogoCardState();
}

class _ReceiptLogoCardState extends ConsumerState<ReceiptLogoCard> {
  bool _busy = false;

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.invalidate(receiptLogoProvider);
    } on LogoProcessingException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to update the logo: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp'],
        ),
      ],
    );
    if (file == null) return;
    await _guard(() async {
      final settings = ref.read(appSettingsProvider);
      await ref
          .read(receiptLogoStoreProvider)
          .save(
            await file.readAsBytes(),
            LogoPrintStyle.parse(settings.receiptLogoStyle),
          );
      await ref
          .read(appSettingsProvider.notifier)
          .update((s) => s.copyWith(receiptLogoSource: 'custom'));
    });
  }

  Future<void> _setStyle(LogoPrintStyle style) => _guard(() async {
    await ref.read(receiptLogoStoreProvider).restyle(style);
    await ref
        .read(appSettingsProvider.notifier)
        .update((s) => s.copyWith(receiptLogoStyle: style.name));
  });

  Future<void> _setSource(String source) => _guard(() async {
    if (source == 'custom' &&
        await ref.read(receiptLogoStoreProvider).readPrintable() == null) {
      await _upload();
      return;
    }
    await ref
        .read(appSettingsProvider.notifier)
        .update((s) => s.copyWith(receiptLogoSource: source));
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final logo = ref.watch(receiptLogoProvider);
    final style = LogoPrintStyle.parse(settings.receiptLogoStyle);
    final isCustom = settings.receiptLogoSource == 'custom';

    return SectionCard(
      title: 'Receipt logo',
      description:
          'Printed at the top of every receipt. Uploaded pictures are '
          'converted for receipt printers: white background, trimmed, sized '
          'to the printer (max 384 × 160 dots) and turned into black-and-white '
          'dots, so colours and faint shades still print clearly.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // White "paper" preview at print size.
              Container(
                key: const Key('logoPreview'),
                width: 220,
                height: 110,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: logo.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(child: Text('No logo')),
                  data: (bytes) => bytes == null
                      ? Center(
                          child: Text(
                            'No logo',
                            style: TextStyle(color: theme.colorScheme.outline),
                          ),
                        )
                      : Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          gaplessPlayback: true,
                        ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'default', label: Text('Default')),
                      ButtonSegment(value: 'custom', label: Text('Uploaded')),
                      ButtonSegment(value: 'none', label: Text('No logo')),
                    ],
                    selected: {settings.receiptLogoSource},
                    onSelectionChanged: _busy
                        ? null
                        : (s) => _setSource(s.first),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('uploadLogoButton'),
                    onPressed: _busy ? null : _upload,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined),
                    label: Text(isCustom ? 'Replace logo' : 'Upload logo'),
                  ),
                ],
              ),
            ],
          ),
          if (isCustom) ...[
            const SizedBox(height: 20),
            Text('Print style', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<LogoPrintStyle>(
              segments: [
                for (final s in LogoPrintStyle.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {style},
              onSelectionChanged: _busy ? null : (s) => _setStyle(s.first),
            ),
            const SizedBox(height: 6),
            Text(style.description, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
