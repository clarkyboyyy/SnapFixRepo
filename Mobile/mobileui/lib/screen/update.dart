import 'package:flutter/material.dart';

import '../models/report.dart';
import '../theme/app_theme.dart';
import '../widget/page_header.dart';

/// A single status change, flattened out of the report list.
class ReportUpdate {
  const ReportUpdate({
    required this.reportId,
    required this.reportTitle,
    required this.message,
    required this.at,
    required this.isResolved,
  });

  final String reportId;
  final String reportTitle;
  final String message;
  final DateTime at;
  final bool isResolved;
}

/// Derives the update feed from the reports the resident has filed.
List<ReportUpdate> buildUpdates(List<IssueReport> reports) {
  final updates = <ReportUpdate>[];

  for (final report in reports) {
    updates.add(
      ReportUpdate(
        reportId: report.id,
        reportTitle: report.title,
        message: 'Your report was received and is queued for review.',
        at: report.createdAt,
        isResolved: false,
      ),
    );

    if (report.status != ReportStatus.submitted) {
      updates.add(
        ReportUpdate(
          reportId: report.id,
          reportTitle: report.title,
          message: report.isResolved
              ? 'Status changed to Resolved.'
              : 'Status changed to In Progress.',
          at: report.createdAt.add(const Duration(days: 2)),
          isResolved: report.isResolved,
        ),
      );
    }
  }

  updates.sort((a, b) => b.at.compareTo(a.at));
  return updates;
}

/// Notifications tab: what has happened to the resident's reports.
class UpdatesPage extends StatelessWidget {
  const UpdatesPage({super.key, required this.reports, required this.onReport});

  final List<IssueReport> reports;
  final ValueChanged<IssueReport> onReport;

  @override
  Widget build(BuildContext context) {
    final updates = buildUpdates(reports);

    return Column(
      children: [
        const PageHeader(
          title: 'Updates',
          subtitle: 'Report progress and status changes',
        ),
        Expanded(
          child: updates.isEmpty
              ? const Center(
                  child: Text(
                    'No updates yet.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: updates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _UpdateTile(
                    update: updates[i],
                    onTap: () {
                      final target = reports
                          .where((r) => r.id == updates[i].reportId)
                          .firstOrNull;
                      if (target != null) onReport(target);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({required this.update, required this.onTap});

  final ReportUpdate update;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = update.isResolved ? AppTheme.resolved : AppTheme.pink;

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(
            update.isResolved
                ? Icons.check_circle_outline
                : Icons.campaign_outlined,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          update.reportTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            update.message,
            style: const TextStyle(fontSize: 11.5, height: 1.35),
          ),
        ),
        trailing: Text(
          _relativeTime(update.at),
          style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return '1d ago';
    return '${days}d ago';
  }
}
