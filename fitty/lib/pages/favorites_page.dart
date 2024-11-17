import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final List<String> categories = ["top", "bottom", "shoes", "accessories"];
  List<Map<String, dynamic>> favorites = [];

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('dateSaved', descending: true)
        .get();
    final favoriteList = querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    setState(() {
      favorites = favoriteList;
    });
  }

  Future<void> deleteFavorite(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(id)
          .delete();
      setState(() {
        favorites = favorites.where((favorite) => favorite['id'] != id).toList();
      });
    } catch (e) {
      print('Error deleting favorite: $e');
    }
  }

  Future<void> shareToFeed(Map<String, dynamic> favorite) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final username = userDoc['username'];

    try {
      await FirebaseFirestore.instance.collection('sharedOutfits').add({
        'userId': user.uid,
        'username': username,
        'name': favorite['name'],
        'dateSaved': favorite['dateSaved'],
        'top': favorite['top'],
        'bottom': favorite['bottom'],
        'shoes': favorite['shoes'],
        'accessories': favorite['accessories'],
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Outfit shared to feed!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error sharing outfit: $e'),
      ));
    }
  }

  void showOutfitDetails(Map<String, dynamic> favorite) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite['name'],
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...categories.map((category) {
                    return favorite[category] != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Image.network(
                                favorite[category]['url'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: 16),
                            ],
                          )
                        : Container();
                  }).toList(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Favorite Outfits'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final favorite = favorites[index];
          return GestureDetector(
            onTap: () => showOutfitDetails(favorite),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite['name'],
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Date: ${favorite['dateSaved'].toDate().toLocal()}',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        itemBuilder: (context, catIndex) {
                          final category = categories[catIndex];
                          return favorite[category] != null
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Image.network(
                                      favorite[category]['url'],
                                      width: double.infinity,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                    Text(
                                      category.toUpperCase(),
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                )
                              : Container();
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(FontAwesomeIcons.trash, color: Colors.red),
                          onPressed: () => deleteFavorite(favorite['id']),
                        ),
                        IconButton(
                          icon: Icon(FontAwesomeIcons.share, color: Colors.blue),
                          onPressed: () => shareToFeed(favorite),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
