import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// TEMPORARY, DEBUG-ONLY workaround for a server whose SSL certificate
/// chain Android rejects (HandshakeException).
///
/// It only relaxes certificate checking for [_trustedDevHost], and only
/// when running a debug build ([kDebugMode]) — release builds and every
/// other host (e.g. the old login API) keep full certificate validation.
///
/// REMOVE this once the server serves a complete/valid certificate chain.
const _trustedDevHost = 'iungo.citgroupltd.com';

void applyDevCertificateOverride(Dio dio) {
  if (!kDebugMode) return;

  final adapter = dio.httpClientAdapter;
  if (adapter is IOHttpClientAdapter) {
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              host == _trustedDevHost;
      return client;
    };
  }
}
