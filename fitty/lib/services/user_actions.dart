// lib/services/user_actions.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> followUser(String userIdToFollow) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
  final userToFollowDoc = await FirebaseFirestore.instance.collection('users').doc(userIdToFollow).get();

  // Add to following collection of the current user
  await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('following').doc(userIdToFollow).set({
    'username': userToFollowDoc['username'],
    'userId': userIdToFollow,
  });

  // Add to followers collection of the user to be followed
  await FirebaseFirestore.instance.collection('users').doc(userIdToFollow).collection('followers').doc(currentUser.uid).set({
    'username': currentUserDoc['username'],
    'userId': currentUser.uid,
  });
}
