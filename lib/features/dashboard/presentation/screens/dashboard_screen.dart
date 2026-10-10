import 'package:billing_guru/features/reports/presentation/widgets/reports_dashboard_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/copyright_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const ReportsDashboardSection(
        showTitle: false,
        showFilter: true,
        compact: true,
      ),
      bottomNavigationBar: const CopyrightBanner(),
    );
  }
}
