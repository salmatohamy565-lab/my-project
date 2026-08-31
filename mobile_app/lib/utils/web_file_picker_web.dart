import 'dart:async';
import 'dart:html' as html;
import 'dart:io';
import 'dart:typed_data';

class WebPickedFile {
  final Uint8List? bytes;
  final String name;
  final File? file;

  WebPickedFile({this.bytes, required this.name, this.file});
}

Future<WebPickedFile?> pickImageFile() async {
  final completer = Completer<WebPickedFile?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        final resultData = reader.result;
        if (resultData is Uint8List) {
          completer.complete(WebPickedFile(bytes: resultData, name: file.name));
        } else if (resultData is ByteBuffer) {
          completer.complete(WebPickedFile(bytes: resultData.asUint8List(), name: file.name));
        } else {
          completer.complete(null);
        }
      });
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
