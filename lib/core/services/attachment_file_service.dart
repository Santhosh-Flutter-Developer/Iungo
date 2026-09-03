import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads attachment bytes (attaching the Bearer auth header the
/// portal's file endpoints require) and either:
///  - hands the file off to whatever app the device has installed for
///    it (video, audio, Office documents, anything this app doesn't
///    render inline) — see [openExternally], or
///  - returns the raw bytes so an in-app renderer (the PDF preview)
///    can use them directly — see [fetchBytes].
///
/// A tiny in-memory cache means re-opening the same attachment during
/// a session doesn't re-download it.
class AttachmentFileService {
  AttachmentFileService._();

  static final AttachmentFileService instance = AttachmentFileService._();

  final Map<String, Uint8List> _cache = {};

  Dio get _dio => Get.isRegistered<Dio>() ? Get.find<Dio>() : Dio();

  /// Downloads (or returns the cached copy of) the raw bytes at [url].
  Future<Uint8List> fetchBytes(
    String url, {
    Map<String, String>? headers,
  }) async {
    final cached = _cache[url];
    if (cached != null) return cached;

    final response = await _dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: headers,
      ),
    );
    final bytes = Uint8List.fromList(response.data ?? const []);
    _cache[url] = bytes;
    return bytes;
  }

  /// Downloads [url] to a temp file named after [fileName] and asks the
  /// OS to open it — the same experience as opening a downloaded
  /// attachment from WhatsApp or Gmail (a native player for video/
  /// audio, WPS/Office/Sheets for documents, an "Open with" chooser
  /// when more than one app can handle it, and so on).
  Future<OpenResult> openExternally(
    String url,
    String fileName, {
    Map<String, String>? headers,
  }) async {
    final bytes = await fetchBytes(url, headers: headers);
    final dir = await getTemporaryDirectory();
    final safeName = fileName.trim().isEmpty ? 'attachment' : fileName.trim();
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return OpenFilex.open(file.path);
  }
}
