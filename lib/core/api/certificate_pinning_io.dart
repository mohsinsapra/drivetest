import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';

// Pinned: Google Trust Services WE1 intermediate CA (expires 2029-02-20).
// Survives Cloudflare leaf cert renewals. Only needs updating if Google rotates this CA.
// To inspect the current chain: openssl s_client -connect taxiexam.hayatpoetry.com:443 -showcerts
Future<void> applyPinning(Dio dio) async {
  final certBytes =
      (await rootBundle.load('assets/certs/server.pem')).buffer.asUint8List();
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final context = SecurityContext(withTrustedRoots: false);
    context.setTrustedCertificatesBytes(certBytes);
    return HttpClient(context: context);
  };
}
