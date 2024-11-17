// pages/favorites_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesTab extends StatefulWidget {
  @override
  _FavoritesTabState createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  final List<String> categories = ["top", "bottom", "shoes", "accessories"];
  List<Map<String, dynamic>> favorites = [];

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favoritesData = prefs.getString('favorites');
    if (favoritesData != null) {
      List<Map<String, dynamic>> favoriteList = List<Map<String, dynamic>>.from(jsonDecode(favoritesData));
      setState(() {
        favorites = favoriteList;
      });
    }
  }

  Future<void> deleteFavorite(int index) async {
    setState(() {
      favorites.removeAt(index);
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('favorites', jsonEncode(favorites));
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
                    final item = favorite['outfitItems'][category];
                    return item != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.toUpperCase(),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Image.network(
                                'https://gateway.pinata.cloud/ipfs/${item['cid']}',
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
    return favorites.isEmpty
        ? Center(child: Text('No favorites yet'))
        : GridView.builder(
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
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Date: ${favorite['dateSaved']}',
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: categories.length,
                            itemBuilder: (context, catIndex) {
                              final category = categories[catIndex];
                              final item = favorite['outfitItems'][category];
                              return item != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Image.network(
                                          'https://gateway.pinata.cloud/ipfs/${item['cid']}',
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
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteFavorite(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
