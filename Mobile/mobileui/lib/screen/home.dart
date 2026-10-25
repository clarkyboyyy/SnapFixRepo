import 'package:flutter/material.dart';

import '../models/report.dart';
import '../theme/app_theme.dart';
import '../widget/brand.dart';
import '../widget/page_header.dart';
import '../widget/report_card.dart';

/// Landing tab: the resident's own report counts and their latest reports.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.reports,
    required this.onReport,
    required this.onCreate,
  });

  final List<IssueReport> reports;
  final ValueChanged<IssueReport> onReport;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    int count(String status) => reports.where((r) => r.status == status).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Brand(showTagline: true),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionLabel('YOUR REPORT OVERVIEW'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Row(
            children: [
              _Stat(
                label: ReportStatus.submitted,
                value: count(ReportStatus.submitted),
                color: AppTheme.submitted,
              ),
              const SizedBox(width: 8),
              _Stat(
                label: ReportStatus.inProgress,
                value: count(ReportStatus.inProgress),
                color: AppTheme.inProgress,
              ),
              const SizedBox(width: 8),
              _Stat(
                label: ReportStatus.resolved,
                value: count(ReportStatus.resolved),
                color: AppTheme.resolved,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.softPink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your community matters',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Report an issue and help make your barangay better.',
                        style: TextStyle(fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.volunteer_activism_outlined,
                  color: AppTheme.pink,
                  size: 35,
                ),
              ],
            ),
          ),
        ),
        if (reports.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No reports yet. Submit your first community report.'),
          )
        else
          ...reports
              .take(3)
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: ReportCard(report: r, onTap: () => onReport(r)),
                ),
              ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Submit a report'),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
