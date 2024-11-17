import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class CachedDataProvider extends ChangeNotifier {
  DocumentSnapshot? userData;
  List<DocumentSnapshot> following = [];
  List<DocumentSnapshot> followers = [];
  List<DocumentSnapshot> favoriteOutfits = [];
  List<DocumentSnapshot> sharedOutfits = [];
  String? profileImageUrl;
  bool dataFetched = false;

  Future<void> fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch user data
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    userData = userDoc;

    // Fetch following
    QuerySnapshot followingSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following').get();
    following = followingSnapshot.docs;

    // Fetch followers
    QuerySnapshot followersSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('followers').get();
    followers = followersSnapshot.docs;

    // Fetch favorite outfits
    QuerySnapshot favoriteOutfitsSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').get();
    favoriteOutfits = favoriteOutfitsSnapshot.docs;

    // Fetch shared outfits
    QuerySnapshot sharedOutfitsSnapshot = await FirebaseFirestore.instance.collection('sharedOutfits').where('userId', isEqualTo: user.uid).get();
    sharedOutfits = sharedOutfitsSnapshot.docs;

    // Fetch profile image URL if not already fetched
    if (profileImageUrl == null) {
      final storageRef = FirebaseStorage.instance.ref().child('profiles/${user.uid}/profile.jpg');
      try {
        final url = await storageRef.getDownloadURL();
        profileImageUrl = url;
      } catch (e) {
        // Handle error if profile image does not exist
        profileImageUrl = null;
      }
    }

    dataFetched = true;
    notifyListeners();
  }

  Future<void> updateProfileImageUrl(String url) async {
    profileImageUrl = url;
    notifyListeners();
  }

  void clearCache() {
    userData = null;
    following = [];
    followers = [];
    favoriteOutfits = [];
    sharedOutfits = [];
    profileImageUrl = null;
    dataFetched = false;
  }

  void clearData() {
    clearCache();
  }

  Future<void> deleteSharedOutfit(String outfitId) async {
    await FirebaseFirestore.instance.collection('sharedOutfits').doc(outfitId).delete();
    await fetchData(); // Refresh data
  }
}

final cachedDataProvider = CachedDataProvider();
