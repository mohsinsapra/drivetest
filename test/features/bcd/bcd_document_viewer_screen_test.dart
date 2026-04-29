import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/bcd/bcd_document_viewer_screen.dart';

void main() {
  group('useExternalDocumentLauncher', () {
    test('uses external launcher on web', () {
      expect(
        useExternalDocumentLauncher(isWeb: true, platform: TargetPlatform.iOS),
        isTrue,
      );
    });

    test('keeps document inside app on Android', () {
      expect(
        useExternalDocumentLauncher(
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
    });

    test('keeps embedded viewer on iOS', () {
      expect(
        useExternalDocumentLauncher(isWeb: false, platform: TargetPlatform.iOS),
        isFalse,
      );
    });
  });

  group('normalizeDocumentUrl', () {
    test('encodes whitespace in document URLs', () {
      expect(
        normalizeDocumentUrl(
          'https://example.com/api/bcd-media/bcd/documents/foo bar.pdf/',
        ),
        'https://example.com/api/bcd-media/bcd/documents/foo%20bar.pdf/',
      );
    });
  });
}
