import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/providers/font_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default font is Inter', () async {
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    expect(provider.fontFamily, 'Inter');
  });

  test('setFont updates fontFamily', () async {
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    await provider.setFont('Inter');
    expect(provider.fontFamily, 'Inter');
  });

  test('setFont calls notifyListeners', () async {
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    bool notified = false;
    provider.addListener(() => notified = true);
    await provider.setFont('Inter');
    expect(notified, true);
  });

  test('setFont persists to SharedPreferences', () async {
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    await provider.setFont('Inter');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('font_family'), 'Inter');
  });

  test('loads persisted font on init', () async {
    SharedPreferences.setMockInitialValues({'font_family': 'Inter'});
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    expect(provider.fontFamily, 'Inter');
  });
}
