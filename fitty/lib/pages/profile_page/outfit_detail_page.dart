import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OutfitDetailPage extends StatelessWidget {
  final String outfitId;

  OutfitDetailPage({required this.outfitId});

  Future<Map<String, dynamic>?> _getOutfitDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot outfitDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(outfitId)
        .get();

    return outfitDoc.exists ? outfitDoc.data() as Map<String, dynamic>? : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Outfit Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getOutfitDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Outfit not found.'));
          }

          final outfit = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outfit['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                _buildOutfitDetails(outfit),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutfitDetails(Map<String, dynamic> outfit) {
    final List<String> categories = ["top", "bottom", "shoes", "accessories"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((category) {
        return outfit[category] != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Image.network(outfit[category]['url'], fit: BoxFit.cover),
                  SizedBox(height: 16),
                ],
              )
            : Container();
      }).toList(),
    );
  }
}
