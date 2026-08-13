import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A single attachment picked from the camera, photo gallery, or device
/// file browser. [path] is populated on Android/iOS/desktop; [bytes] is
/// populated on web (and optionally elsewhere) since there is no real
/// filesystem path to read from in the browser.
class AttachmentFile extends Equatable {
  const AttachmentFile({
    required this.name,
    this.path,
    this.bytes,
  });

  final String name;
  final String? path;
  final Uint8List? bytes;

  @override
  List<Object?> get props => [name, path, bytes];
}
