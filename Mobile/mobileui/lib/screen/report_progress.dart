import 'dart:async';

import 'package:flutter/material.dart';

import '../models/issuecategory.dart';
import '../theme/app_theme.dart';
import '../ticketservice.dart';
import '../utils/date_format.dart';
import '../widget/page_header.dart';
import 'inquiry.dart';

/// Step-by-step tracking history for a report, plus the admin conversation.
class ReportProgressPage extends StatefulWidget {
  const ReportProgressPage({super.key, required this.report});

  final IssueReport report;

  @override
  State<ReportProgressPage> createState() => _ReportProgressPageState();
}

class _ReportProgressPageState extends State<ReportProgressPage> {
  static const Duration _refreshEvery = Duration(seconds: 5);

  late IssueReport _report = widget.report;
  List<ReportUpdate> _history = [];
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(_refreshEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        TicketService.fetchTicket(_report.id),
        TicketService.fetchUpdates(_report.id),
      ]);
      if (!mounted) return;

      final ticket = Map<String, dynamic>.from(results[0] as Map);
      final updates = (results[1] as List)
          .map(
            (item) =>
                ReportUpdate.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      setState(() {
        _report = IssueReport.fromJson(ticket);
        _history = updates;
      });
    } catch (_) {
      // Keep the last known state; the next poll will retry.
    }
  }

  /// Index of the stage the report currently sits at.
  int get _currentStage {
    if (_report.isResolved) return 3;
    if (_report.status == ReportStatus.inProgress) return 2;
    if (_report.progress > 0) return 1;
    return 0;
  }

  Future<void> _openInquiry() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => InquiryPage(report: _report)));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final stage = _currentStage;
    final color = AppTheme.statusColor(report.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Progress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            report.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 5),
          Text(
            report.id,
            style: const TextStyle(color: AppTheme.muted, fontSize: 11),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.softPink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Completion',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
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
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: report.progress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                if (report.assignedDepartment != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Assigned to ${report.assignedDepartment}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(2, 22, 2, 10),
            child: SectionLabel('TRACKING HISTORY'),
          ),
          if (_history.isNotEmpty)
            for (var i = 0; i < _history.length; i++)
              _TimelineRow(
                label: _history[i].status ?? 'Progress update',
                detail: _historyDetail(_history[i]),
                done: true,
                isLast: i == _history.length - 1,
              )
          else
            for (var i = 0; i < _stages.length; i++)
              _TimelineRow(
                label: _stages[i],
                detail: _details[i],
                done: i <= stage,
                isLast: i == _stages.length - 1,
              ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline, size: 16, color: AppTheme.pink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.isResolved
                      ? 'Resolved on ${report.location}. Reopen a report if the '
                            'issue returns.'
                      : 'Questions and replies stay attached to this report, so '
                            'the admin always sees the full history.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: AppTheme.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: FilledButton.icon(
          onPressed: _openInquiry,
          icon: const Icon(Icons.question_answer_outlined, size: 18),
          label: const Text('Ask the admin about this status'),
        ),
      ),
    );
  }

  static String _historyDetail(ReportUpdate update) {
    return [
      if (update.note != null) update.note!,
      '${update.progress}% complete',
      messageStamp(update.createdAt),
    ].join(' • ');
  }

  static const List<String> _stages = [
    'Report submitted',
    'Under review',
    'Assigned to a work crew',
    'Issue resolved',
  ];

  static const List<String> _details = [
    'Your report reached the barangay hall.',
    'A staff member is checking the report.',
    'The repair has been scheduled.',
    'The work is complete and verified.',
  ];
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.detail,
    required this.done,
    required this.isLast,
  });

  final String label;
  final String detail;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? AppTheme.pink : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? AppTheme.pink : AppTheme.border,
                  ),
                ),
                child: Icon(
                  done ? Icons.check : Icons.circle,
                  size: done ? 15 : 9,
                  color: done ? Colors.white : AppTheme.muted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppTheme.pink : AppTheme.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: done ? AppTheme.charcoal : AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
