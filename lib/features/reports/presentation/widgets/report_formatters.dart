import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency.dart';
import 'package:flutter/material.dart';

String formatReportCurrency(int cents, AppCurrency currency) {
  return CurrencyFormatter.formatCents(cents, currency: currency);
}

String formatCompactReportCurrency(int cents, AppCurrency currency) {
  return CurrencyFormatter.formatCompactCents(cents, currency: currency);
}

String formatReportDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}

String formatFullReportDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String formatPaymentMethod(String paymentMethod) {
  if (paymentMethod.trim().isEmpty) {
    return 'Unknown';
  }

  return paymentMethod
      .split('_')
      .map((word) {
        if (word.isEmpty) {
          return word;
        }

        return '${word[0].toUpperCase()}'
            '${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}

Color reportChartColor(int index) {
  const colors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFF00838F),
    Color(0xFF5D4037),
  ];

  return colors[index % colors.length];
}
