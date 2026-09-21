import 'package:dio/dio.dart';

/// Web / non-dart:io platforms: nothing to do (the browser handles TLS).
void applyDevCertificateOverride(Dio dio) {}

/// Web: nothing to do (the browser handles TLS).
void applyDevCertificateOverrideGlobally() {}
