// Picks the real implementation on mobile/desktop (dart:io) and a no-op on
// Flutter Web, so the web build still compiles.
export 'dev_certificate_override_stub.dart'
    if (dart.library.io) 'dev_certificate_override_io.dart';
