import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Confirmation shown right after a report is filed.
class SubmittedReportPage extends StatelessWidget {
  const SubmittedReportPage({
    super.key,
    required this.reportId,
    required this.onViewReports,
    required this.onBackToHome,
  });

  final String? reportId;
  final VoidCallback onViewReports;
  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    final id = reportId;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6F4EC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          size: 52,
                          color: AppTheme.resolved,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Report Submitted!',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your report is with the barangay hall. You will see status '
                        'changes on the Updates tab.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.muted,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                      if (id != null) ...[
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softPink,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'REFERENCE NUMBER',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  letterSpacing: .7,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.pink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                id,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onViewReports,
                          child: const Text('View My Reports'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: onBackToHome,
                        child: const Text('Back to home'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
