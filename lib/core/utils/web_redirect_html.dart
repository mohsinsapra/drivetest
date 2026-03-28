// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void performRedirect(String url) {
  html.window.location.href = url;
}
