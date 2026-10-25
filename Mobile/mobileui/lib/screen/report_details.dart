import 'dart:io';

import 'package:flutter/material.dart';

import '../models/report.dart';
import '../theme/app_theme.dart';
import '../widget/page_header.dart';
import '../widget/report_card.dart';
import 'report_progress.dart';

/// Everything known about one report, and the entry point to its history.
class ReportDetailsPage extends StatelessWidget {
  const ReportDetailsPage({
    super.key,
    required this.report,
    required this.onDelete,
  });

  final IssueReport report;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final photo = report.photoPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete report',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            report.id,
            style: const TextStyle(color: AppTheme.muted, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            report.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusPill(status: report.status),
          ),
          if (photo != null) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(photo),
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _MissingPhoto(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _InfoCard(
            title: 'ISSUE INFORMATION',
            children: [
              _InfoRow(
                icon: IssueCategory.byLabel(report.category).icon,
                label: 'Category',
                value: report.category,
              ),
              _InfoRow(
                icon: Icons.description_outlined,
                label: 'Description',
                value: report.description,
              ),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: report.location,
              ),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Reported',
                value: _formatDateTime(report.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressCard(report: report),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const Icon(Icons.timeline, color: AppTheme.pink),
              title: const Text(
                'Report Progress',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('View report tracking history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportProgressPage(report: report),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '$hour:$minute $period';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 14),
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppTheme.pink),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.report});

  final IssueReport report;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(report.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('CURRENT PROGRESS')),
              Text(
                '${report.progress}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: report.progress / 100,
              minHeight: 8,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.isResolved
                ? 'This issue has been closed by your barangay.'
                : 'Your barangay is working on this issue.',
            style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      color: AppTheme.surface,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: AppTheme.muted, size: 30),
          SizedBox(height: 8),
          Text(
            'Photo is no longer on this device',
            style: TextStyle(fontSize: 11.5, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}
