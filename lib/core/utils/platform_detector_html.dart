// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'platform_detector.dart';

WebPlatform detectWebPlatformImpl() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  if (ua.contains('android')) return WebPlatform.android;
  if (ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod')) {
    return WebPlatform.ios;
  }
  return WebPlatform.none;
}
