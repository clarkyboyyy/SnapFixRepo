import 'package:flutter/material.dart';

/// A community issue that a resident can report to the barangay.
class IssueReport {
  IssueReport({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
    this.photoPath,
    this.progress = 0,
    List<InquiryMessage>? messages,
  }) : messages = messages ?? [];

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

  /// Conversation thread between the resident and the barangay admin.
  final List<InquiryMessage> messages;

  bool get isResolved => status == ReportStatus.resolved;
  bool get isOpen => status == ReportStatus.submitted;

  InquiryMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  bool get hasUnreadAdmin =>
      messages.any((message) => message.fromAdmin && !message.seen);

  int get unreadFromAdmin =>
      messages.where((message) => message.fromAdmin && !message.seen).length;

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
      messages: messages,
    );
  }
}

enum InquiryAuthor { user, admin }

/// One message in the resident ↔ admin conversation about a report.
class InquiryMessage {
  InquiryMessage({
    required this.text,
    required this.author,
    required this.sentAt,
    this.seen = true,
  });

  final String text;
  final InquiryAuthor author;
  final DateTime sentAt;
  bool seen;

  bool get fromAdmin => author == InquiryAuthor.admin;
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
