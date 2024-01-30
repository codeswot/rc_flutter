import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageHandler {
  final recordingsRef = FirebaseStorage.instance.ref('recordings/');

  Future<String> uploadData(Uint8List data) async {
    final task =
        await recordingsRef.child('${DateTime.now().hashCode}.wav').putData(
            data,
            SettableMetadata(
              contentType: 'audio/aac',
            ));
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadFile(File file) async {
    final task =
        await recordingsRef.child('${DateTime.now().hashCode}.aac').putFile(
              file,
              SettableMetadata(
                contentType: 'audio/aac',
              ),
            );
    return await task.ref.getDownloadURL();
  }
}
