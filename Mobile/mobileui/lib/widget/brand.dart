import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'logo.dart';

/// The logo mark plus the SnapFix wordmark.
class Brand extends StatelessWidget {
  const Brand({super.key, this.logoSize = 44, this.showTagline = false});

  final double logoSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Logo(size: logoSize),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SnapFix',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                  height: 1.1,
                ),
              ),
              if (showTagline)
                const Text(
                  'Report it. Track it. Fixed.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
