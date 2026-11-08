import 'package:flutter/material.dart';
import '../ticketservice.dart';
import '../models/issuecategory.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widget/report_card.dart';

/// Chat-style thread where a resident asks the barangay admin about the
/// status of a report.
class InquiryPage extends StatefulWidget {
  const InquiryPage({super.key, required this.report});

  final IssueReport report;

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  static const List<String> _prompts = [
    'Any update on my report?',
    'When will this be fixed?',
    'Who is assigned to this?',
  ];

  IssueReport get _report => widget.report;
  List<InquiryMessage> get _messages => _report.messages;

  bool get _waitingForAdmin =>
      _messages.isNotEmpty && !_messages.last.fromAdmin;

  @override
  void initState() {
    super.initState();
    for (final message in _messages) {
      if (message.fromAdmin) message.seen = true;
    }
    _controller.addListener(_onDraftChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _onDraftChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onDraftChanged);
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

 Future<void> _send() async {
  final text = _controller.text.trim();
  if (text.isEmpty) return;
  
  // Save the text before clearing the controller
  final sentText = text;
  
  // Clear UI immediately for a snappy feel
  setState(() {
    _controller.clear();
  });
  _focus.unfocus();

  try {
    // Transmit to C# API
    await TicketService.sendMessage(_report.id, sentText);

    // Update the chat bubble list ONLY if successful
    setState(() {
      _messages.add(
        InquiryMessage(
          text: sentText,
          author: InquiryAuthor.user,
          sentAt: DateTime.now(),
        ),
      );
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $e')),
      );
    }
  }
}

  void _usePrompt(String prompt) {
    _controller.text = prompt;
    _controller.selection = TextSelection.collapsed(offset: prompt.length);
    _focus.requestFocus();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask the Admin',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
            ),
            Text(
              '${_report.id} • ${_report.status}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.statusColor(_report.status),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _ReportStrip(report: _report),
                const SizedBox(height: 14),
                _ReplyBanner(
                  hasMessages: _messages.isNotEmpty,
                  waiting: _waitingForAdmin,
                ),
                const SizedBox(height: 18),
                if (_messages.isEmpty)
                  const _EmptyThread()
                else
                  for (final message in _messages)
                    _MessageBubble(message: message),
              ],
            ),
          ),
          _Composer(
            controller: _controller,
            focusNode: _focus,
            prompts: _prompts,
            canSend: _controller.text.trim().isNotEmpty,
            onPrompt: _usePrompt,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ReportStrip extends StatelessWidget {
  const _ReportStrip({required this.report});

  final IssueReport report;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(report.status);
    final category = IssueCategory.byLabel(report.category);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.softPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, size: 17, color: AppTheme.pink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${report.id} • ${report.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(status: report.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${report.progress}% complete',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reported ${shortDate(report.createdAt)}',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.progress / 100,
              minHeight: 6,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.hasMessages, required this.waiting});

  final bool hasMessages;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final (
      Color tint,
      Color accent,
      IconData icon,
      String title,
      String body,
    ) = switch ((hasMessages, waiting)) {
      (false, _) => (
        AppTheme.softPink,
        AppTheme.pink,
        Icons.forum_outlined,
        'Ask anything about this report',
        'The barangay admin usually replies within 1 day.',
      ),
      (true, true) => (
        const Color(0xFFFFF4E0),
        AppTheme.inProgress,
        Icons.hourglass_top_rounded,
        'Waiting for the admin to reply',
        'Your question stays in this thread — no need to ask again.',
      ),
      (true, false) => (
        const Color(0xFFE9F6EE),
        AppTheme.resolved,
        Icons.task_alt_rounded,
        'The admin replied',
        'Replies come from Barangay San Isidro staff.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: AppTheme.softPink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 27,
              color: AppTheme.pink,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'No messages yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ask about the status, schedule, or who is working on your '
            'report. The admin reply will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final InquiryMessage message;

  @override
  Widget build(BuildContext context) {
    final fromAdmin = message.fromAdmin;
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.74,
      ),
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        color: fromAdmin ? Colors.white : AppTheme.pink,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(fromAdmin ? 4 : 16),
          bottomRight: Radius.circular(fromAdmin ? 16 : 4),
        ),
        border: fromAdmin ? Border.all(color: AppTheme.border) : null,
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 12.5,
          height: 1.45,
          color: fromAdmin ? AppTheme.charcoal : Colors.white,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: fromAdmin
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (fromAdmin) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppTheme.softPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                size: 16,
                color: AppTheme.pink,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: fromAdmin
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (fromAdmin)
                  const Padding(
                    padding: EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      'Barangay Admin',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: AppTheme.muted,
                      ),
                    ),
                  ),
                bubble,
                const SizedBox(height: 4),
                Text(
                  messageStamp(message.sentAt),
                  style: const TextStyle(fontSize: 9.5, color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.prompts,
    required this.canSend,
    required this.onPrompt,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> prompts;
  final bool canSend;
  final ValueChanged<String> onPrompt;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: prompts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 7),
                  itemBuilder: (_, index) => ActionChip(
                    label: Text(prompts[index]),
                    onPressed: () => onPrompt(prompts[index]),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        style: const TextStyle(fontSize: 12.5),
                        decoration: const InputDecoration(
                          hintText: 'Type your question for the admin…',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: canSend ? AppTheme.pink : AppTheme.border,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: canSend ? onSend : null,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.send_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
