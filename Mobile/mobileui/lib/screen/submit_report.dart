import 'dart:io';

import '../ticketservice.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/issuecategory.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widget/page_header.dart';

/// The "New Report" form: what the issue is, where it is, and an optional
/// photo. Builds an [IssueReport] and hands it to [onSubmitted]; the caller
/// owns persistence and navigation.
///
class SubmitReportPage extends StatefulWidget {
  const SubmitReportPage({
    super.key,
    required this.onSubmitted,
    this.accountEmail,
  });

  final void Function(IssueReport report) onSubmitted;

  /// Signed-in resident; the report is filed under this account.
  final String? accountEmail;

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
  DeviceLocation? _coordinates;
  bool _picking = false;
  bool _locating = false;
  bool _isSubmitting = false; // <-- Prevents multiple taps and UI freezing

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  static const int _maxPhotoBytes = 5 * 1024 * 1024;
  static const Set<String> _allowedPhotoExtensions = {'.jpg', '.jpeg', '.png'};

  /// Counts whitespace-separated words, so the form limits match the messages.
  static int _wordCount(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  Future<String?> _validatePhoto(XFile file) async {
    final name = file.name.toLowerCase();
    final extension = name.contains('.')
        ? name.substring(name.lastIndexOf('.'))
        : '';
    final mime = (file.mimeType ?? '').toLowerCase();
    final formatAllowed =
        _allowedPhotoExtensions.contains(extension) ||
        mime == 'image/jpeg' ||
        mime == 'image/png';

    if (!formatAllowed) {
      return 'Only JPG, JPEG, and PNG images are allowed.';
    }

    final int size;
    try {
      size = await file.length();
    } on Exception {
      return 'Please select a valid image.';
    }

    if (size <= 0) return 'Please select a valid image.';
    if (size > _maxPhotoBytes) return 'Photo size must not exceed 5 MB.';

    return null;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(source: source);
      if (file == null) return;

      final error = await _validatePhoto(file);
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }

      if (mounted) setState(() => _photo = File(file.path));
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

  /// Asks for permission and stores the device's current GPS fix.
  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final location = await LocationService.currentLocation();
      if (!mounted) return;
      setState(() => _coordinates = location);

      // Show the barangay/street name; numbers only when the lookup fails.
      final placeName = await LocationService.describe(location);
      if (!mounted) return;

      final label = placeName ?? 'GPS ${location.label}';
      // The text field is still required by the form; a captured fix fills it
      // so the resident can submit without typing the address as well.
      if (_location.text.trim().isEmpty) {
        _location.text = label;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location captured: $label')),
      );
    } on LocationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _submit() async {
    if (_isSubmitting) return;
    if (!_form.currentState!.validate()) return;

    setState(() => _isSubmitting = true); // Lock UI

    try {
      // A fresh id per submission; generating it once per app run made every
      // report after the first collide with PK_tickets.
      final newId = 'SF-${DateTime.now().millisecondsSinceEpoch}';
      String title = _title.text.trim();
      String description = _description.text.trim();
      String categoryLabel = _category?.label ?? 'General';
      String? photoPath = _photo?.path;

      // Best effort: a denied GPS must never block the report itself.
      var coordinates = _coordinates;
      if (coordinates == null) {
        try {
          coordinates = await LocationService.currentLocation();
        } on LocationException {
          coordinates = null;
        }
      }

      // GPS alone is enough for the location text; typing an address still wins.
      var location = _location.text.trim();
      if (location.isEmpty && coordinates != null) {
        location = 'GPS ${coordinates.label}';
      }

      // 1. Send the report with a 10-second timeout so it doesn't hang forever
      await TicketService.submitTicket(
        newId,
        title,
        location,
        description,
        category: categoryLabel,
        userEmail: widget.accountEmail,
        latitude: coordinates?.latitude,
        longitude: coordinates?.longitude,
      ).timeout(const Duration(seconds: 10));
      if (mounted) {
        Navigator.pop(context);
      }

      // 2. Build the IssueReport instance
      final report = IssueReport(
        id: newId,
        title: title,
        category: categoryLabel,
        description: description,
        location: location,
        status: ReportStatus.submitted,
        createdAt: DateTime.now(),
        photoPath: photoPath,
        progress: 0,
        latitude: coordinates?.latitude,
        longitude: coordinates?.longitude,
      );

      // 3. Notify parent screen
      widget.onSubmitted(report);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report submitted successfully!")),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Submission failed: $e")));
    } finally {
      // 4. CRUCIAL: Always unlock the UI whether it succeeds or fails
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    const _FieldLabel('Issue title (max 10 words)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Broken streetlight on Rizal Ave',
                        counterStyle: TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.muted,
                        ),
                      ),
                      validator: (v) {
                        final title = v?.trim() ?? '';
                        if (title.isEmpty) return 'Issue title is required.';
                        if (_wordCount(title) > 10) {
                          return 'Issue title must not exceed 10 words.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Description (max 200 words)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _description,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText:
                            'What exactly is wrong, and since when? Add anything '
                            'that helps the crew find it.',
                        counterStyle: TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.muted,
                        ),
                      ),
                      validator: (v) {
                        final description = v ?? '';
                        if (description.trim().isEmpty) {
                          return 'Description is required.';
                        }
                        if (_wordCount(description) > 200) {
                          return 'Description must not exceed 200 words.';
                        }
                        return null;
                      },
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
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) &&
                              _coordinates == null
                          ? 'Enter where the issue is'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _locating
                                ? null
                                : _useCurrentLocation,
                            icon: _locating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                    size: 18,
                                  ),
                            label: Text(
                              _locating
                                  ? 'Getting location...'
                                  : 'Use my current location',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_coordinates != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed,
                            size: 14,
                            color: AppTheme.pink,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'GPS: ${_coordinates!.label}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.muted,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Reports are routed to your barangay hall.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.muted,
                            ),
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
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: AppTheme.muted,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Supported formats: JPG, PNG | Maximum size: 5 MB',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.muted,
                            ),
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
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: _isSubmitting
              ? null
              : _submit, // <-- Disables button and prevents freeze
          icon: _isSubmitting
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 19),
          label: Text(_isSubmitting ? 'Submitting...' : 'Submit New Report'),
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
    return BoxConstraints == BoxConstraints
        ? Wrap(
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
                    color: selected == category
                        ? AppTheme.pink
                        : AppTheme.muted,
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
          )
        : const Wrap();
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
