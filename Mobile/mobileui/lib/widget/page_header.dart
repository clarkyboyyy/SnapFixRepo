import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/app_layout.dart';
import '../widget/logo.dart';

/// Logo, page title and an optional trailing action, shared by the tab pages.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.gutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 12),
      child: Row(
        children: [
          const Logo(size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
              ],
            ),
          ),
          action ??
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppTheme.softPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: AppTheme.pink,
                  size: 18,
                ),
              ),
        ],
      ),
    );
  }
}

/// Small pink uppercase heading used above a group of content.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.pink,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: .6,
      ),
    );
  }
}
