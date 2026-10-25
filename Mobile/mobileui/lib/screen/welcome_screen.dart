import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widget/logo.dart';

/// First launch: introduces SnapFix and offers the guided tour.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onSkip,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: TextButton(
                  onPressed: onSkip,
                  child: const Text("Guest Mode"),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        const Logo(size: 92),
                        const SizedBox(height: 28),
                        const Text(
                          'SnapFix',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Report it. Track it. Fixed.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.pink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Spot a pothole, a broken streetlight or uncollected '
                          'garbage? Send it to your barangay in seconds and '
                          'follow the repair from your phone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: onGetStarted,
                    child: const Text('Get Started'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No account needed to file your first report.',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
