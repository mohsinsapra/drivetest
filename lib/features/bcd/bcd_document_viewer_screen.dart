import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

bool useExternalDocumentLauncher({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) return true;
  return false;
}

String normalizeDocumentUrl(String url) => Uri.encodeFull(url);

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
  late Future<Uint8List> _pdfBytesFuture;

  bool get _useExternalLauncher => useExternalDocumentLauncher(
        isWeb: kIsWeb,
        platform: Theme.of(context).platform,
      );

  @override
  void initState() {
    super.initState();
    _pdfBytesFuture = _loadPdfBytes();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeLaunchExternally());
  }

  Future<Uint8List> _loadPdfBytes() async {
    final response = await DioClient().dio.get<List<int>>(
          normalizeDocumentUrl(widget.url),
          options: Options(responseType: ResponseType.bytes),
        );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw Exception('Document response was empty');
    }
    return Uint8List.fromList(data);
  }

  Future<void> _maybeLaunchExternally() async {
    if (!mounted || !_useExternalLauncher) return;

    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      showAppSnackBar('Could not open document.', type: SnackBarType.error);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_useExternalLauncher) {
      // Web keeps the browser-native handling path.
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<Uint8List>(
        future: _pdfBytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load document.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _pdfBytesFuture = _loadPdfBytes();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SfPdfViewer.memory(
            snapshot.data!,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            pageSpacing: 12,
          );
        },
      ),
    );
  }
}
