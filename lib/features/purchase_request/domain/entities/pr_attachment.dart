import 'package:iungo/core/constants/app_urls.dart';

/// One file attached to a Purchase Request — an entry of the Purchase
/// Request API's `attachments[]`, `delivery_notes[]` or `invoices[]`
/// (the API returns each as a plain URL string).
class PrAttachment {
  const PrAttachment({
    required this.url,
    required this.name,
    required this.apiFileName,
  });

  /// Builds an attachment from the URL the API returned. The name is the
  /// last path segment of that URL, e.g.
  /// `https://iungo.citgroupltd.com/include/images/upload/Iungo_Portal_API_Guide.pdf`
  /// -> `Iungo_Portal_API_Guide.pdf`.
  factory PrAttachment.fromUrl(String rawUrl) {
    final url = _absolute(rawUrl.trim());
    final name = _fileNameOf(url);
    return PrAttachment(url: url, name: name, apiFileName: name);
  }

  /// The full, absolute URL to download/open the file from.
  final String url;

  /// What the UI shows for this file.
  final String name;

  /// What the approve API's `selected_attachments` expects for this file
  /// (the stored file name — never a URL or a local path). Today this is
  /// the same text as [name]; it is kept as its own field so the two can
  /// diverge in one place if the backend ever needs a different value.
  final String apiFileName;

  /// Lower-case file extension without the dot, e.g. `pdf` / `jpg`
  /// (empty when the name has none).
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static String _fileNameOf(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed != null && parsed.pathSegments.isNotEmpty) {
      final last = parsed.pathSegments.last;
      if (last.isNotEmpty) return last;
    }
    final withoutQuery = url.split('?').first.split('#').first;
    final slash = withoutQuery.lastIndexOf('/');
    final tail = slash == -1 ? withoutQuery : withoutQuery.substring(slash + 1);
    return tail.isEmpty ? url : tail;
  }

  /// The API normally returns absolute URLs. A host-relative path or a
  /// bare file name is resolved against the Iungo upload folder (the one
  /// every example URL in the API guide points at) so it can still be
  /// opened.
  static String _absolute(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${AppUrls.iungoHost}$url';
    return '${AppUrls.iungoUploadBase}/$url';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PrAttachment && other.url == url);

  @override
  int get hashCode => url.hashCode;
}
