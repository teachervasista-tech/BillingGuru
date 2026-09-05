import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
  scaffoldBackgroundColor: const Color(0xFFF5F7FA),
  appBarTheme: AppBarTheme(
    backgroundColor: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0))
        .primary,
    foregroundColor: Colors.white,
    centerTitle: false,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  ),
);
