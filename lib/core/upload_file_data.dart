import 'dart:typed_data';

class UploadFileData {
  const UploadFileData({
    required this.name,
    this.path,
    this.bytes,
  });

  final String name;
  final String? path;
  final Uint8List? bytes;
}
