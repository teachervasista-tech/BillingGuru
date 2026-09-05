import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class BillingGuru extends StatelessWidget {
  const BillingGuru({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Billing Guru',
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}
