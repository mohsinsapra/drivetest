import 'platform_detector_stub.dart'
    if (dart.library.html) 'platform_detector_html.dart';

enum WebPlatform { android, ios, none }

WebPlatform detectWebPlatform() => detectWebPlatformImpl();
