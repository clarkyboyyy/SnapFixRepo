import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Provided transitively by image_picker; used here to fake the platform.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mobileui/screen/submit_report.dart';
import 'package:mobileui/theme/app_theme.dart';

class _FakeImagePicker extends ImagePickerPlatform {
  _FakeImagePicker(this.file);

  final XFile file;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return file;
  }
}

void main() {
  testWidgets('rejects a photo larger than 5 MB', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bigPhoto = XFile.fromData(
      Uint8List(6 * 1024 * 1024),
      name: 'big-photo.jpg',
      mimeType: 'image/jpeg',
    );

    ImagePickerPlatform.instance = _FakeImagePicker(bigPhoto);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SubmitReportPage(onSubmitted: (_) {}),
      ),
    );

    await tester.tap(find.text('Gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Photo size must not exceed 5 MB.'), findsOneWidget);
    expect(find.text('Take or choose a photo'), findsOneWidget);
  });
}
