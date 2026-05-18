// ignore: avoid_web_libraries_in_flutter
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter, duplicate_ignore

import 'dart:html' as html;

class WebCameraHelper {
  static Future<bool> hasWebCamera() async {
    try {
      var devices =
          await html.window.navigator.mediaDevices?.enumerateDevices();
      if (devices == null) return false;
      return devices.any((d) => d.kind == "videoinput");
    } catch (_) {
      return false;
    }
  }

  static Future<void> pickFromCamera(
      void Function(String base64Image) onImagePicked) async {
    final html.FileUploadInputElement input = html.FileUploadInputElement();
    input.accept = 'image/*;capture=camera';
    input.click();

    input.onChange.listen((event) {
      final file = input.files!.first;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((event) {
        final base64 = reader.result.toString().split(',').last;
        onImagePicked(base64);
      });
    });
  }
}
