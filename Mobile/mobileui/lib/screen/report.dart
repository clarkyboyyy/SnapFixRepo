import 'package:flutter/material.dart';

import '../models/report.dart';
import '../theme/app_theme.dart';
import '../widget/page_header.dart';
import '../widget/report_card.dart';

/// "My Reports" tab: the resident's reports filtered by lifecycle stage.
class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    required this.reports,
    required this.onReport,
    this.initialFilter = 'All',
  });

  final List<IssueReport> reports;
  final ValueChanged<IssueReport> onReport;
  final String initialFilter;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late String _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final visible = widget.reports
        .where((r) => _filter == 'All' || r.status == _filter)
        .toList();

    return Column(
      children: [
        const PageHeader(
          title: 'My Reports',
          subtitle: 'Track the issues you have reported',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final status in ReportStatus.filters)
                _FilterChip(
                  label: status,
                  selected: _filter == status,
                  onTap: () => setState(() => _filter = status),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: visible.isEmpty
              ? const _EmptyState(filter: 'this status')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => ReportCard(
                    report: visible[i],
                    onTap: () => widget.onReport(visible[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppTheme.softPink,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppTheme.pink : AppTheme.border),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: AppTheme.softPink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: AppTheme.pink,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No reports in $filter.',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'New submissions will show up here.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}
