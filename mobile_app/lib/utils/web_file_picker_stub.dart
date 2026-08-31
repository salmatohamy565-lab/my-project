import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class WebPickedFile {
  final Uint8List? bytes;
  final String name;
  final File? file;

  WebPickedFile({this.bytes, required this.name, this.file});
}

Future<WebPickedFile?> pickImageFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result != null && result.files.isNotEmpty) {
    final pf = result.files.single;
    return WebPickedFile(
      bytes: pf.bytes,
      name: pf.name,
      file: pf.path != null ? File(pf.path!) : null,
    );
  }
  return null;
}
