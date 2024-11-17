import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowersPage extends StatelessWidget {
  final String userId;

  FollowersPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('followers')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var followers = snapshot.data!.docs.where((doc) => doc.id != userId).toList();

          if (followers.isEmpty) {
            return Center(child: Text('No followers found'));
          }

          return ListView.builder(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              var follower = followers[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(follower.id)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  var userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                  var username = userData != null && userData.containsKey('username') ? userData['username'] : 'No username';

                  return ListTile(
                    title: Text(username),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
