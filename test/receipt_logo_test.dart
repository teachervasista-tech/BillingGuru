import 'dart:io';
import 'dart:typed_data';

import 'package:billing_guru/core/printing/receipt_logo.dart';
import 'package:billing_guru/core/printing/receipt_logo_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// 1000x600 transparent canvas with a red-to-blue gradient box in the
/// middle (300..700 x 200..400) and a faint yellow stripe.
Uint8List _colourLogo() {
  final image = img.Image(width: 1000, height: 600, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  for (var y = 200; y < 400; y++) {
    for (var x = 300; x < 700; x++) {
      final t = (x - 300) / 400;
      image.setPixelRgba(
        x,
        y,
        (255 * (1 - t)).round(),
        0,
        (255 * t).round(),
        255,
      );
    }
  }
  for (var x = 300; x < 700; x++) {
    image.setPixelRgba(x, 420, 255, 240, 120, 255);
  }
  return img.encodePng(image);
}

Set<int> _levels(img.Image image) => {for (final p in image) p.r.toInt()};

void main() {
  test('black & white: white background, trimmed, sized, two levels only', () {
    final out = img.decodePng(
      ReceiptLogoProcessor.process(_colourLogo(), LogoPrintStyle.blackAndWhite),
    )!;
    // Content is 400x221 -> scaled to fit 384x160 keeping aspect.
    expect(out.width, lessThanOrEqualTo(ReceiptLogoProcessor.maxWidth));
    expect(out.height, lessThanOrEqualTo(ReceiptLogoProcessor.maxHeight));
    expect(out.height, ReceiptLogoProcessor.maxHeight);
    expect(_levels(out), {0, 255});
    expect(out.numChannels, 1, reason: 'stored as grayscale, no alpha');
    // The coloured box prints as ink.
    expect(out.getPixel(out.width ~/ 2, out.height ~/ 3).r, 0);
  });

  test('dithered output is pure black/white; grayscale keeps shades', () {
    final dithered = img.decodePng(
      ReceiptLogoProcessor.process(_colourLogo(), LogoPrintStyle.dithered),
    )!;
    expect(_levels(dithered), {0, 255});

    final gray = img.decodePng(
      ReceiptLogoProcessor.process(_colourLogo(), LogoPrintStyle.grayscale),
    )!;
    expect(_levels(gray).length, greaterThan(2));
  });

  test('small logos are not upscaled', () {
    final small = img.Image(width: 40, height: 20);
    img.fill(small, color: img.ColorRgb8(0, 0, 0));
    final out = img.decodePng(
      ReceiptLogoProcessor.process(
        img.encodePng(small),
        LogoPrintStyle.grayscale,
      ),
    )!;
    expect((out.width, out.height), (40, 20));
  });

  test('blank or unreadable images are rejected', () {
    final blank = img.Image(width: 50, height: 50);
    img.fill(blank, color: img.ColorRgb8(255, 255, 255));
    expect(
      () => ReceiptLogoProcessor.process(
        img.encodePng(blank),
        LogoPrintStyle.blackAndWhite,
      ),
      throwsA(isA<LogoProcessingException>()),
    );
    expect(
      () => ReceiptLogoProcessor.process(
        Uint8List.fromList([1, 2, 3]),
        LogoPrintStyle.blackAndWhite,
      ),
      throwsA(isA<LogoProcessingException>()),
    );
  });

  test('store keeps the original so the style can change later', () async {
    final dir = await Directory.systemTemp.createTemp('bg_logo_');
    addTearDown(() => dir.delete(recursive: true));
    final store = ReceiptLogoStore(root: () async => dir);

    expect(await store.readPrintable(), isNull);
    await store.save(_colourLogo(), LogoPrintStyle.blackAndWhite);
    final bw = img.decodePng((await store.readPrintable())!)!;
    expect(_levels(bw), {0, 255});

    await store.restyle(LogoPrintStyle.grayscale);
    final gray = img.decodePng((await store.readPrintable())!)!;
    expect(_levels(gray).length, greaterThan(2));

    await store.delete();
    expect(await store.readPrintable(), isNull);
  });
}
