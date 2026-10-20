import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _radius = 10.0;

/// A selectable color theme, defined in assets/config/color_themes.json.
class AppColorTheme {
  const AppColorTheme({
    required this.id,
    required this.label,
    required this.seed,
  });

  final String id;
  final String label;
  final Color seed;

  static const fallback = AppColorTheme(
    id: 'blue',
    label: 'Blue',
    seed: Color(0xFF1565C0),
  );

  static List<AppColorTheme> options = const [fallback];
  static AppColorTheme selected = fallback;

  /// Reads the themes and applies the one named by "selected" in the file;
  /// keeps the built-in blue theme on any error.
  static Future<void> load() async {
    try {
      final text = await rootBundle.loadString(
        'assets/config/color_themes.json',
      );
      final json = jsonDecode(text) as Map<String, dynamic>;
      final loaded = <AppColorTheme>[];
      for (final entry in (json['themes'] as List<dynamic>? ?? const [])) {
        final map = entry as Map<String, dynamic>;
        final id = map['id'] as String?;
        final color = _parseColor(map['color'] as String?);
        if (id == null || color == null) continue;
        loaded.add(
          AppColorTheme(
            id: id,
            label: map['label'] as String? ?? id,
            seed: color,
          ),
        );
      }
      if (loaded.isEmpty) return;
      options = loaded;
      selected = loaded.firstWhere(
        (theme) => theme.id == json['selected'],
        orElse: () => loaded.first,
      );
    } catch (_) {
      options = const [fallback];
      selected = fallback;
    }
  }

  static Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
  }
}

/// Type scale used across the app:
/// - page / panel heading: headlineSmall
/// - card or section heading: titleMedium
/// - sub heading / field group: titleSmall
/// - body text: bodyMedium, hints: bodySmall
ThemeData buildAppTheme(AppColorTheme colorTheme) {
  final colorScheme = ColorScheme.fromSeed(seedColor: colorTheme.seed);
  final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
  final textTheme = base.textTheme.copyWith(
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    ),
    titleSmall: base.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_radius),
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    iconTheme: const IconThemeData(size: 24),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
    ),
    cardTheme: CardThemeData(shape: shape),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: shape),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: shape),
    ),
  );
}
