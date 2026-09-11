import 'package:flutter/material.dart';

class CopyrightBanner extends StatelessWidget {
  const CopyrightBanner({
    super.key,
    this.companyName = 'BillingGuru',
    this.year = 2026,
  });

  final String companyName;
  final int year;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Text(
          '© $year $companyName. All rights reserved. Powered by Vasista Technologies',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
