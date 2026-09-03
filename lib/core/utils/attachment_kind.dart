/// Broad classification of an attachment — decides how the Attachments
/// tab's "View" action should render it: an inline preview (image/pdf)
/// vs. handing the file off to whatever app the device has for it
/// (video, audio, Office documents, everything else).
enum AttachmentKind { image, pdf, video, audio, other }

const _imageExtensions = {
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif',
};
const _videoExtensions = {
  'mp4', 'mov', 'mkv', 'avi', 'webm', '3gp', 'm4v',
};
const _audioExtensions = {
  'mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus', 'flac',
};

/// Classifies an attachment from whatever the server/mapper gave us —
/// prefers the server's `contentType` (MIME) and falls back to the file
/// extension when it's missing or unrecognised.
AttachmentKind classifyAttachment({String? contentType, String? extension}) {
  final type = (contentType ?? '').trim().toLowerCase();
  if (type.startsWith('image/')) return AttachmentKind.image;
  if (type == 'application/pdf') return AttachmentKind.pdf;
  if (type.startsWith('video/')) return AttachmentKind.video;
  if (type.startsWith('audio/')) return AttachmentKind.audio;

  final ext = (extension ?? '').trim().toLowerCase().replaceFirst('.', '');
  if (ext == 'pdf') return AttachmentKind.pdf;
  if (_imageExtensions.contains(ext)) return AttachmentKind.image;
  if (_videoExtensions.contains(ext)) return AttachmentKind.video;
  if (_audioExtensions.contains(ext)) return AttachmentKind.audio;
  return AttachmentKind.other;
}
