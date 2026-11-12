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
    this.photoUrl,
    this.progress = 0,
    this.assignedDepartment,
    this.adminNotes,
    List<InquiryMessage>? messages,
    List<ReportUpdate>? history,
  }) : messages = messages ?? [],
       history = history ?? [];

  /// Parses a ticket row from the REST API, accepting both the camelCase the
  /// Flutter app sends and the snake_case the database uses.
  factory IssueReport.fromJson(Map<String, dynamic> json) {
    final rawDate =
        json['dateSubmitted'] ?? json['date_submitted'] ?? json['createdAt'];
    final rawProgress = json['progress'];
    final progress = rawProgress is num
        ? rawProgress.toInt()
        : int.tryParse('${rawProgress ?? ''}') ?? 0;

    return IssueReport(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled').toString(),
      category: (json['category'] ?? 'Others').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      status: ReportStatus.normalize(json['status']?.toString()),
      createdAt:
          DateTime.tryParse(rawDate?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      photoPath: _optionalString(json['photoPath'] ?? json['photo_path']),
      photoUrl: _optionalString(json['photoUrl'] ?? json['photo_url']),
      progress: progress.clamp(0, 100),
      assignedDepartment: _optionalString(
        json['assignedDepartment'] ?? json['assigned_department'],
      ),
      adminNotes: _optionalString(json['adminNotes'] ?? json['admin_notes']),
    );
  }

  final String id;
  final String title;
  final String category;
  final String description;
  final String location;
  final String status;
  final DateTime createdAt;

  /// Local file path of the attached photo, if the reporter added one.
  final String? photoPath;

  /// URL of the photo once the backend has stored it.
  final String? photoUrl;

  /// Completion of the barangay's work on this report, 0–100.
  final int progress;

  /// Department the admin assigned the ticket to.
  final String? assignedDepartment;

  /// Notes the admin saved with the ticket.
  final String? adminNotes;

  /// Conversation thread between the resident and the barangay admin.
  final List<InquiryMessage> messages;

  /// Status/progress changes logged by the admin, newest first.
  final List<ReportUpdate> history;

  bool get isResolved => status == ReportStatus.resolved;
  bool get isOpen => status == ReportStatus.submitted;

  InquiryMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  bool get hasUnreadAdmin =>
      messages.any((message) => message.fromAdmin && !message.seen);

  int get unreadFromAdmin =>
      messages.where((message) => message.fromAdmin && !message.seen).length;

  IssueReport copyWith({
    String? id,
    String? status,
    int? progress,
    String? photoPath,
    String? photoUrl,
    String? assignedDepartment,
    String? adminNotes,
    List<InquiryMessage>? messages,
    List<ReportUpdate>? history,
  }) {
    return IssueReport(
      id: id ?? this.id,
      title: title,
      category: category,
      description: description,
      location: location,
      status: status ?? this.status,
      createdAt: createdAt,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      progress: progress ?? this.progress,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      adminNotes: adminNotes ?? this.adminNotes,
      messages: messages ?? this.messages,
      history: history ?? this.history,
    );
  }
}

/// One entry in the ticket's tracking history, written by the admin.
class ReportUpdate {
  const ReportUpdate({
    this.id = 0,
    this.status,
    this.progress = 0,
    this.note,
    required this.createdAt,
  });

  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'] ?? json['created_at'];
    final rawProgress = json['progress'];
    return ReportUpdate(
      id: json['id'] is int ? json['id'] as int : 0,
      status: _optionalString(json['status']),
      progress: rawProgress is num ? rawProgress.toInt() : 0,
      note: _optionalString(json['note']),
      createdAt:
          DateTime.tryParse(rawDate?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  final int id;
  final String? status;
  final int progress;
  final String? note;
  final DateTime createdAt;
}

String? _optionalString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

enum InquiryAuthor { user, admin }

/// One message in the resident ↔ admin conversation about a report.
class InquiryMessage {
  InquiryMessage({
    this.id = 0,
    required this.text,
    required this.author,
    required this.sentAt,
    this.seen = true,
  });

  factory InquiryMessage.fromJson(Map<String, dynamic> json) {
    final sender = (json['senderType'] ?? json['sender_type'] ?? '')
        .toString()
        .toLowerCase();
    final rawDate =
        json['dateSent'] ?? json['date_sent'] ?? json['createdAt'];
    final rawId = json['id'];

    return InquiryMessage(
      id: rawId is int ? rawId : int.tryParse('${rawId ?? ''}') ?? 0,
      text: (json['message'] ?? json['text'] ?? '').toString(),
      author: sender == 'admin' ? InquiryAuthor.admin : InquiryAuthor.user,
      sentAt:
          DateTime.tryParse(rawDate?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      seen: sender != 'admin',
    );
  }

  final int id;
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

  /// Maps whichever status wording the backend or web admin stored onto the
  /// three states this app displays.
  static String normalize(String? value) {
    final status = (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    if (status == 'ongoing' ||
        status == 'in progress' ||
        status == 'inprogress' ||
        status == 'assigned' ||
        status == 'working') {
      return inProgress;
    }
    if (status == 'resolved' ||
        status == 'closed' ||
        status == 'completed' ||
        status == 'done') {
      return resolved;
    }
    return submitted;
  }
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
    IssueCategory('Others', Icons.more_horiz),
  ];

  static IssueCategory byLabel(String label) =>
      values.firstWhere((c) => c.label == label, orElse: () => values.first);
}
