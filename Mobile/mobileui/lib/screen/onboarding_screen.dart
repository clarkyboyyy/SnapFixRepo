import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Three-page tour of the report flow: photograph, locate, track.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onFinished,
    required this.onSkip,
  });

  final VoidCallback onFinished;
  final VoidCallback onSkip;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _steps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() => _page = page);

    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _steps[i];

                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 168,
                              height: 168,
                              decoration: const BoxDecoration(
                                color: AppTheme.softPink,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                s.icon,
                                size: 74,
                                color: AppTheme.pink,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              s.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              s.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.6,
                                color: AppTheme.muted,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppTheme.pink : AppTheme.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
            ),

            // Back and Next/Get Started buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Row(
                children: [
                  if (_page > 0)
                    OutlinedButton(
                      onPressed: () => _goTo(_page - 1),
                      child: const Text('Back'),
                    ),
                  if (_page > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLast
                          ? widget.onFinished
                          : () => _goTo(_page + 1),
                      child: Text(_isLast ? 'Get Started' : 'Next'),
                    ),
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

class _Step {
  const _Step(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

const List<_Step> _steps = [
  _Step(
    Icons.photo_camera_outlined,
    'Snap the problem',
    'Take a photo on the spot and pick the category that fits. Two taps and '
        'the report is ready to send.',
  ),
  _Step(
    Icons.location_on_outlined,
    'Pin the exact spot',
    'Add the street, purok or nearest landmark so the crew does not have to '
        'go looking for it.',
  ),
  _Step(
    Icons.check_circle_outline,
    'Track it to fixed',
    'Watch every report move from submitted to in progress to resolved, right '
        'from your phone.',
  ),
];
