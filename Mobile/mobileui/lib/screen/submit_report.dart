import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report.dart';
import '../theme/app_theme.dart';
import '../widget/page_header.dart';

/// The "New Report" form: what the issue is, where it is, and an optional
/// photo. Builds an [IssueReport] and hands it to [onSubmitted]; the caller
/// owns persistence and navigation.
class SubmitReportPage extends StatefulWidget {
  const SubmitReportPage({super.key, required this.onSubmitted});

  final void Function(IssueReport report) onSubmitted;

  @override
  State<SubmitReportPage> createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _picker = ImagePicker();

  IssueCategory? _category;
  File? _photo;
  bool _picking = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file != null) setState(() => _photo = File(file.path));
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Camera is not available on this device.'
                  : 'Could not open the photo gallery.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    widget.onSubmitted(
      IssueReport(
        id: '',
        title: _title.text.trim(),
        category: _category!.label,
        description: _description.text.trim(),
        location: _location.text.trim(),
        status: ReportStatus.submitted,
        photoPath: _photo?.path,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Report'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tell us what needs fixing in your barangay.',
                style: TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel('NEW REPORT'),
              const SizedBox(height: 12),
              _FormCard(
                title: 'What’s the issue?',
                children: [
                  const _FieldLabel('Category'),
                  const SizedBox(height: 8),
                  FormField<IssueCategory>(
                    initialValue: _category,
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CategoryPicker(
                            selected: state.value,
                            hasError: state.hasError,
                            onSelected: (c) {
                              state.didChange(c);
                              setState(() => _category = c);
                            },
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                state.errorText ?? 'Choose a category',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFD93B3B),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    validator: (v) => v == null ? 'Choose a category' : null,
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Issue title'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Broken streetlight on Rizal Ave',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Give the issue a short title'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'What exactly is wrong, and since when? Add anything '
                          'that helps the crew find it.',
                    ),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Describe the issue in at least a few words'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FormCard(
                title: 'Location',
                children: [
                  TextFormField(
                    controller: _location,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Street, purok or nearest landmark',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.pink,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter where the issue is'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppTheme.muted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Reports are routed to your barangay hall.',
                          style: TextStyle(fontSize: 11, color: AppTheme.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FormCard(
                title: 'Add a photo',
                subtitle:
                    'Optional, but reports with a photo are triaged faster.',
                children: [
                  _PhotoTile(
                    photo: _photo,
                    busy: _picking,
                    onTap: () => _pickPhoto(ImageSource.camera),
                    onRemove: () => setState(() => _photo = null),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _picking
                              ? null
                              : () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            size: 18,
                          ),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _picking
                              ? null
                              : () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                          ),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_rounded, size: 19),
          label: const Text('Submit New Report'),
        ),
      ),
    );
  }
}

/// White rounded container that groups one stage of the form.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.charcoal,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
            ),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.charcoal,
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.selected,
    required this.hasError,
    required this.onSelected,
  });

  final IssueCategory? selected;
  final bool hasError;
  final ValueChanged<IssueCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in IssueCategory.values)
          ChoiceChip(
            selected: selected == category,
            onSelected: (_) => onSelected(category),
            avatar: Icon(
              category.icon,
              size: 16,
              color: selected == category ? AppTheme.pink : AppTheme.muted,
            ),
            label: Text(category.label),
            showCheckmark: false,
            selectedColor: AppTheme.softPink,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected == category
                  ? AppTheme.pink
                  : hasError
                  ? const Color(0xFFD93B3B)
                  : AppTheme.border,
            ),
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.busy,
    required this.onTap,
    required this.onRemove,
  });

  final File? photo;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = photo;

    if (selected == null) {
      return InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        mouseCursor: busy ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Container(
          height: 132,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.softPink),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppTheme.softPink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppTheme.pink,
                    size: 22,
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Take or choose a photo',
                style: TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            selected,
            height: 168,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 168,
              color: AppTheme.surface,
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppTheme.muted,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 1,
            child: IconButton(
              onPressed: onRemove,
              iconSize: 18,
              color: AppTheme.charcoal,
              tooltip: 'Remove photo',
              icon: const Icon(Icons.close),
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 13, color: AppTheme.softPink),
                SizedBox(width: 5),
                Text(
                  'Photo attached',
                  style: TextStyle(fontSize: 10.5, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
