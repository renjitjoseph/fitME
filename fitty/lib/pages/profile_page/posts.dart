import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostsPage extends StatefulWidget {
  final DocumentSnapshot post;

  PostsPage({required this.post});

  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  late Map<String, dynamic> postData;

  @override
  void initState() {
    super.initState();
    postData = widget.post.data() as Map<String, dynamic>;
  }

  Future<void> _unsharePost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('feed').doc(widget.post.id).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post unshared successfully')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (postData.containsKey('imageUrl'))
              Image.network(postData['imageUrl'])
            else
              Text('No image available'),
            SizedBox(height: 10),
            Text(postData.containsKey('name') ? postData['name'] : 'Unnamed Outfit'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _unsharePost,
              child: Text('Unshare'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
