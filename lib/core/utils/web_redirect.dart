import 'web_redirect_stub.dart' if (dart.library.html) 'web_redirect_html.dart';

/// Redirects the current browser window to [url].
/// No-op on non-web platforms.
void redirectToUrl(String url) => performRedirect(url);
