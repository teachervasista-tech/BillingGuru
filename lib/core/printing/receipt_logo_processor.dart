import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// How an uploaded logo is converted for printing.
enum LogoPrintStyle {
  blackAndWhite(
    'Black & white',
    'Sharpest on thermal receipt printers. Best for logos and text.',
  ),
  dithered(
    'Dithered',
    'Thermal printers, for photos or shaded logos (dot pattern).',
  ),
  grayscale('Grayscale', 'Laser or inkjet printers.');

  const LogoPrintStyle(this.label, this.description);

  final String label;
  final String description;

  static LogoPrintStyle parse(String? value) => LogoPrintStyle.values
      .firstWhere((s) => s.name == value, orElse: () => blackAndWhite);
}

class LogoProcessingException implements Exception {
  const LogoProcessingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Converts any picture into a print-ready receipt logo.
///
/// Receipt printers print black dots on white paper at ~203 dpi, so colour
/// is useless and transparency, soft edges and large sizes print badly.
/// The result is a white-background PNG trimmed to its content, at most
/// [maxWidth] x [maxHeight] pixels (384 dots = the 48 mm printable width of a
/// 58 mm roll, so it prints at native resolution on 58 mm and 80 mm printers).
class ReceiptLogoProcessor {
  const ReceiptLogoProcessor._();

  static const maxWidth = 384;
  static const maxHeight = 160;

  /// Pixels lighter than this count as background when trimming.
  static const _backgroundLuma = 245;

  static Uint8List process(Uint8List bytes, LogoPrintStyle style) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const LogoProcessingException(
        'Unsupported image. Use PNG, JPG, BMP, GIF or WEBP.',
      );
    }

    // 1. Flatten transparency onto white paper, as luminance (0-255).
    final width = decoded.width;
    final height = decoded.height;
    final luma = Uint8List(width * height);
    for (final pixel in decoded) {
      final alpha = pixel.aNormalized.toDouble();
      final y =
          0.299 * pixel.rNormalized +
          0.587 * pixel.gNormalized +
          0.114 * pixel.bNormalized;
      luma[pixel.y * width + pixel.x] = ((y * alpha + (1 - alpha)) * 255)
          .round()
          .clamp(0, 255);
    }

    // 2. Trim the white border so the logo uses the whole print area.
    var left = width, right = -1, top = height, bottom = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (luma[y * width + x] < _backgroundLuma) {
          if (x < left) left = x;
          if (x > right) right = x;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
    }
    if (right < 0) {
      throw const LogoProcessingException(
        'The image is blank (white or transparent).',
      );
    }
    final cropW = right - left + 1;
    final cropH = bottom - top + 1;
    var gray = img.Image(width: cropW, height: cropH, numChannels: 1);
    for (var y = 0; y < cropH; y++) {
      for (var x = 0; x < cropW; x++) {
        final v = luma[(y + top) * width + (x + left)];
        gray.setPixelRgb(x, y, v, v, v);
      }
    }

    // 3. Downscale to the printer's dot size (never upscale: it only blurs).
    final scale = [
      1.0,
      maxWidth / cropW,
      maxHeight / cropH,
    ].reduce((a, b) => a < b ? a : b);
    if (scale < 1) {
      gray = img.copyResize(
        gray,
        width: (cropW * scale).round().clamp(1, maxWidth),
        height: (cropH * scale).round().clamp(1, maxHeight),
        interpolation: img.Interpolation.average,
      );
    }

    // 4. Stretch contrast so faint colours still print.
    final values = Uint8List(gray.width * gray.height);
    for (final p in gray) {
      values[p.y * gray.width + p.x] = p.r.toInt();
    }
    _stretch(values);

    // 5. Apply the print style.
    switch (style) {
      case LogoPrintStyle.blackAndWhite:
        final t = _otsuThreshold(values);
        for (var i = 0; i < values.length; i++) {
          values[i] = values[i] <= t ? 0 : 255;
        }
      case LogoPrintStyle.dithered:
        _floydSteinberg(values, gray.width, gray.height);
      case LogoPrintStyle.grayscale:
        break;
    }

    final out = img.Image(
      width: gray.width,
      height: gray.height,
      numChannels: 1,
    );
    for (var y = 0; y < out.height; y++) {
      for (var x = 0; x < out.width; x++) {
        final v = values[y * out.width + x];
        out.setPixelRgb(x, y, v, v, v);
      }
    }
    return img.encodePng(out);
  }

  /// Maps the darkest pixel to black and the lightest to white.
  static void _stretch(Uint8List values) {
    var lo = 255, hi = 0;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    if (hi - lo < 8) return;
    final range = hi - lo;
    for (var i = 0; i < values.length; i++) {
      values[i] = ((values[i] - lo) * 255 / range).round();
    }
  }

  /// Threshold that best separates ink from paper (Otsu's method).
  static int _otsuThreshold(Uint8List values) {
    final histogram = List<int>.filled(256, 0);
    for (final v in values) {
      histogram[v]++;
    }
    final total = values.length;
    var sum = 0.0;
    for (var i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }
    var sumBackground = 0.0;
    var weightBackground = 0;
    var bestVariance = -1.0;
    var threshold = 127;
    for (var t = 0; t < 256; t++) {
      weightBackground += histogram[t];
      if (weightBackground == 0) continue;
      final weightForeground = total - weightBackground;
      if (weightForeground == 0) break;
      sumBackground += t * histogram[t];
      final meanB = sumBackground / weightBackground;
      final meanF = (sum - sumBackground) / weightForeground;
      final variance =
          weightBackground *
          weightForeground *
          (meanB - meanF) *
          (meanB - meanF);
      if (variance > bestVariance) {
        bestVariance = variance;
        threshold = t;
      }
    }
    return threshold;
  }

  /// Error-diffusion to pure black/white dots.
  static void _floydSteinberg(Uint8List values, int width, int height) {
    final buffer = Float64List.fromList(
      values.map((v) => v.toDouble()).toList(),
    );
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final old = buffer[i];
        final value = old < 128 ? 0.0 : 255.0;
        final error = old - value;
        buffer[i] = value;
        if (x + 1 < width) buffer[i + 1] += error * 7 / 16;
        if (y + 1 < height) {
          if (x > 0) buffer[i + width - 1] += error * 3 / 16;
          buffer[i + width] += error * 5 / 16;
          if (x + 1 < width) buffer[i + width + 1] += error * 1 / 16;
        }
      }
    }
    for (var i = 0; i < values.length; i++) {
      values[i] = buffer[i] <= 127 ? 0 : 255;
    }
  }
}
