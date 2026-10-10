import 'package:flutter/material.dart';

import '../widgets/reports_dashboard_section.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [ReportsDashboardSection(showTitle: false)],
      ),
    );
  }
}
