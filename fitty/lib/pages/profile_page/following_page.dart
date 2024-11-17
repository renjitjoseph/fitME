import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowingPage extends StatelessWidget {
  final String userId;

  FollowingPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Following'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('following')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var following = snapshot.data!.docs.where((doc) => doc.id != userId).toList();

          if (following.isEmpty) {
            return Center(child: Text('No following found'));
          }

          return ListView.builder(
            itemCount: following.length,
            itemBuilder: (context, index) {
              var follow = following[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(follow.id)
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
