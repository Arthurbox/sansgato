import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploade une image vers Firebase Storage et retourne l'URL publique
  static Future<String> uploadImage(XFile imageFile, String folderPath) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final String destination = '$folderPath/$fileName';
      
      final Reference ref = _storage.ref().child(destination);
      
      // Upload
      final UploadTask uploadTask = ref.putFile(File(imageFile.path));
      
      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception("Erreur lors de l'upload sur Firebase Storage : $e");
    }
  }
}
