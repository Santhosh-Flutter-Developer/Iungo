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

/// The same workaround, applied process-wide via [HttpOverrides.global].
///
/// [Dio] instances only need [applyDevCertificateOverride] above, but a
/// few widgets (`Image.network`, for a quotation/delivery-note image
/// attachment) talk to [_trustedDevHost] through Flutter's own
/// `HttpClient` with no way to hand it a per-request override, so this
/// covers those. Safe to call once at startup: still debug-only, and
/// still scoped to [_trustedDevHost] alone.
void applyDevCertificateOverrideGlobally() {
  if (!kDebugMode) return;
  HttpOverrides.global = _DevCertificateHttpOverrides();
}

class _DevCertificateHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            host == _trustedDevHost;
    return client;
  }
}