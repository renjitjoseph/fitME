// pages/shuffle_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shuffle_provider.dart';
import '../providers/wardrobe_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ShufflePage extends StatefulWidget {
  @override
  _ShufflePageState createState() => _ShufflePageState();
}

class _ShufflePageState extends State<ShufflePage> {
  final List<String> categories = ["accessories", "top", "bottom", "shoes"];
  String favoriteName = '';
  bool showModal = false;
  bool showNameModal = false;
  bool isShuffling = false;

  Future<Map<String, dynamic>?> fetchCategoryItems(String category) async {
    final wardrobeProvider = Provider.of<WardrobeProvider>(context, listen: false);
    final items = wardrobeProvider.wardrobeItems[category];
    if (items != null && items.isNotEmpty) {
      final randomIndex = DateTime.now().millisecondsSinceEpoch % items.length;
      return items[randomIndex];
    } else {
      return null;
    }
  }

  Future<void> shuffleOutfits() async {
    setState(() {
      isShuffling = true;
    });

    final Map<String, dynamic> newItems = {};
    for (final category in categories) {
      if (!Provider.of<ShuffleProvider>(context, listen: false).locks[category]!) {
        newItems[category] = await fetchCategoryItems(category);
      } else {
        newItems[category] = Provider.of<ShuffleProvider>(context, listen: false).outfitItems[category];
      }
    }
    Provider.of<ShuffleProvider>(context, listen: false).updateOutfitItems(newItems);

    setState(() {
      isShuffling = false;
    });
  }

  Future<void> saveToFavorites() async {
    final outfitItems = Provider.of<ShuffleProvider>(context, listen: false).outfitItems;

    Map<String, dynamic> favoriteItem = {
      'name': favoriteName.isNotEmpty ? favoriteName : 'Favorite',
      'dateSaved': DateTime.now().toIso8601String(),
      'outfitItems': outfitItems,
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favoritesData = prefs.getString('favorites');
    List<Map<String, dynamic>> favoritesList = favoritesData != null
        ? List<Map<String, dynamic>>.from(jsonDecode(favoritesData))
        : [];
    favoritesList.add(favoriteItem);
    await prefs.setString('favorites', jsonEncode(favoritesList));

    setState(() {
      showModal = true;
      favoriteName = '';
    });
  }

  void handleSaveClick() {
    setState(() {
      showNameModal = true;
    });
  }

  void unlockAllCategories() {
    final shuffleProvider = Provider.of<ShuffleProvider>(context, listen: false);
    for (final category in categories) {
      if (shuffleProvider.locks[category] == true) {
        shuffleProvider.toggleLock(category);
      }
    }
  }

  Widget buildCategory(String category) {
    final item = Provider.of<ShuffleProvider>(context).outfitItems[category];
    final isLocked = Provider.of<ShuffleProvider>(context).locks[category]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${category.toUpperCase()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (item != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'https://gateway.pinata.cloud/ipfs/${item['cid']}',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: -10,
                  top: -10,
                  child: IconButton(
                    icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
                    color: Colors.black,
                    onPressed: () {
                      Provider.of<ShuffleProvider>(context, listen: false).toggleLock(category);
                    },
                  ),
                ),
              ],
            ),
          if (item == null)
            Container(
              width: 100,
              height: 100,
              color: Colors.grey[400],
              child: Center(
                child: Text('None'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: categories.map((category) => buildCategory(category)).toList(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          onPressed: handleSaveClick,
                          child: FaIcon(FontAwesomeIcons.heart, color: Colors.black),
                          backgroundColor: Colors.white,
                          elevation: 4,
                        ),
                        SizedBox(height: 20),
                        FloatingActionButton(
                          onPressed: isShuffling ? null : shuffleOutfits,
                          child: isShuffling
                              ? CircularProgressIndicator(color: Colors.black)
                              : FaIcon(FontAwesomeIcons.shuffle, color: Colors.black),
                          backgroundColor: Colors.white,
                          elevation: 4,
                        ),
                        SizedBox(height: 20),
                        FloatingActionButton(
                          onPressed: unlockAllCategories,
                          child: Icon(Icons.lock_open, color: Colors.black),
                          backgroundColor: Colors.white,
                          elevation: 4,
                          tooltip: 'Unlock All',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showNameModal)
              AlertDialog(
                title: Text('Enter Favorite Name'),
                content: TextField(
                  onChanged: (value) {
                    setState(() {
                      favoriteName = value;
                    });
                  },
                  decoration: InputDecoration(hintText: 'Favorite name'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      saveToFavorites();
                      setState(() {
                        showNameModal = false;
                      });
                    },
                    child: Text('Save'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showNameModal = false;
                      });
                    },
                    child: Text('Cancel'),
                  ),
                ],
              ),
            if (showModal)
              AlertDialog(
                title: Text('Saved'),
                content: Text('Outfit saved to favorites!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showModal = false;
                      });
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
