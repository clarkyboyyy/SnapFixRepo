import 'dart:io';

import 'package:flutter/material.dart';

import '../models/issuecategory.dart';
import '../theme/app_theme.dart';

/// Renders a report's photo wherever the app shows one: from the uploaded URL
/// when the backend has it, from the local file while it is still only on this
/// device, and with a placeholder when it is missing or fails to load.
class ReportPhoto extends StatelessWidget {
  const ReportPhoto({
    super.key,
    required this.report,
    this.height = 210,
    this.width = double.infinity,
    this.radius = 18,
    this.placeholderLabel = 'Photo unavailable',
    this.emptyFallback,
  });

  final IssueReport report;
  final double height;
  final double width;
  final double radius;
  final String placeholderLabel;

  /// Shown when the report has no photo at all. Defaults to nothing, so list
  /// rows stay compact.
  final Widget? emptyFallback;

  @override
  Widget build(BuildContext context) {
    final url = report.photoUrl?.trim();
    final localPath = report.photoPath?.trim();

    final Widget image;
    if (url != null && url.isNotEmpty) {
      image = Image.network(
        url,
        height: height,
        width: width,
        fit: BoxFit.cover,
        loadingBuilder: _loading,
        errorBuilder: (_, _, _) => _Placeholder(
          height: height,
          width: width,
          label: 'Photo could not be loaded',
        ),
      );
    } else if (localPath != null && localPath.isNotEmpty) {
      image = Image.file(
        File(localPath),
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _Placeholder(
          height: height,
          width: width,
          label: 'Photo is no longer on this device',
        ),
      );
    } else {
      return emptyFallback ?? const SizedBox.shrink();
    }

    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }

  Widget _loading(
    BuildContext context,
    Widget child,
    ImageChunkEvent? progress,
  ) {
    if (progress == null) return child; // The first frame is ready to paint.

    final total = progress.expectedTotalBytes;
    final showLabel = height >= 64;
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppTheme.surface),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showLabel && total != null && total > 0)
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: (progress.cumulativeBytesLoaded / total).clamp(
                        0.0,
                        1.0,
                      ),
                      minHeight: 4,
                      color: AppTheme.pink,
                      backgroundColor: AppTheme.border,
                    ),
                  )
                else
                  SizedBox(
                    width: showLabel ? 24 : 14,
                    height: showLabel ? 24 : 14,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppTheme.pink,
                    ),
                  ),
                if (showLabel) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Loading photo',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.height,
    required this.width,
    required this.label,
  });

  final double height;
  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    // A thumbnail is too small to carry the explanation as well as the icon.
    final showLabel = height >= 64;

    return Container(
      height: height,
      width: width,
      color: AppTheme.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: AppTheme.muted,
            size: showLabel ? 30 : 18,
          ),
          if (showLabel) ...[
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}
