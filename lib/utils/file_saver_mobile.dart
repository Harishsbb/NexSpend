import 'package:flutter/foundation.dart';

Future<void> saveFile(Uint8List bytes, String fileName) async {
  // Fallback for non-web platforms (e.g. mobile/desktop)
  debugPrint('Save file is only implemented for Web. Cannot save: $fileName');
}
