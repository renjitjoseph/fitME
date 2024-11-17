import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedService {
  Future<List<Map<String, dynamic>>> fetchFeed(List<String> following) async {
    // Check if the following list is empty before querying
    if (following.isEmpty) {
      return [];
    }

    try {
      // Query the sharedOutfits collection for outfits shared by users the current user is following
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sharedOutfits')
          .where('userId', whereIn: following)
          .orderBy('dateSaved', descending: true)
          .get();

      // Transform the snapshot to a list of maps
      List<Map<String, dynamic>> feed = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      return feed;
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> fetchFollowing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Fetch the 'following' subcollection of the current user
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .get();

      List<String> following = querySnapshot.docs.map((doc) => doc.id).toList();
      return following;
    } catch (e) {
      return [];
    }
  }

  Future<void> followUser(String userIdToFollow) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .doc(userIdToFollow)
          .set({}); // Add an empty document to signify following
    } catch (e) {
      // Handle errors if necessary
    }
  }
}
