import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class BCDDocumentViewerScreen extends StatefulWidget {
  final String title;
  final String url;

  const BCDDocumentViewerScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<BCDDocumentViewerScreen> createState() =>
      _BCDDocumentViewerScreenState();
}

class _BCDDocumentViewerScreenState extends State<BCDDocumentViewerScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Web: can't use InAppWebView — open via url_launcher on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final uri = Uri.parse(widget.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (mounted) {
          showAppSnackBar('Could not open document.', type: SnackBarType.error);
        }
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Show a brief loading state while the url_launcher opens
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            onLoadStop: (_, __) {
              if (mounted) setState(() => _loading = false);
            },
            onReceivedError: (_, __, ___) {
              if (mounted) setState(() => _loading = false);
            },
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
