import 'package:flutter/material.dart';

/// A community issue that a resident can report to the barangay.
class IssueReport {
  const IssueReport({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
    this.photoPath,
    this.progress = 0,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String location;
  final String status;
  final DateTime createdAt;

  /// Local file path of the attached photo, if the reporter added one.
  final String? photoPath;

  /// Completion of the barangay's work on this report, 0–100.
  final int progress;

  bool get isResolved => status == ReportStatus.resolved;
  bool get isOpen => status == ReportStatus.submitted;

  IssueReport copyWith({String? id, String? status, int? progress}) {
    return IssueReport(
      id: id ?? this.id,
      title: title,
      category: category,
      description: description,
      location: location,
      status: status ?? this.status,
      createdAt: createdAt,
      photoPath: photoPath,
      progress: progress ?? this.progress,
    );
  }
}

/// The lifecycle states a report moves through.
class ReportStatus {
  ReportStatus._();

  static const String submitted = 'Submitted';
  static const String inProgress = 'In Progress';
  static const String resolved = 'Resolved';

  static const List<String> filters = ['All', submitted, inProgress, resolved];
}

/// Issue types offered on the report form, each with a recognisable icon.
class IssueCategory {
  const IssueCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static const List<IssueCategory> values = [
    IssueCategory('Street Lighting', Icons.lightbulb_outline),
    IssueCategory('Waste Management', Icons.delete_outline),
    IssueCategory('Roads & Infrastructure', Icons.add_road_outlined),
    IssueCategory('Waterways & Drainage', Icons.water_drop_outlined),
    IssueCategory('Public Safety', Icons.local_police_outlined),
    IssueCategory('Parks & Greenery', Icons.park_outlined),
  ];

  static IssueCategory byLabel(String label) =>
      values.firstWhere((c) => c.label == label, orElse: () => values.first);
}
