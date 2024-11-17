import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> uploadImage(File imageFile, Map<String, dynamic> uploadPayload) async {
    try {
      // Upload image to Firebase Storage
      String fileName = imageFile.path.split('/').last;
      Reference storageRef = _storage.ref().child('images/$fileName');
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get image URL
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Add image URL to the upload payload
      uploadPayload['imageUrl'] = imageUrl;

      // Save upload payload to Firestore
      await _firestore.collection('images').add(uploadPayload);
    } catch (e) {
      print('Error uploading image: $e');
    }
  }
}
