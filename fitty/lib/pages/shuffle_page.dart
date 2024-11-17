import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import '../providers/shuffle_provider.dart';

enum ColorCategory { neutral, warm, cool }

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final itemsRef = FirebaseStorage.instance.ref().child('wardrobe/${user.uid}/$category');
    final listResult = await itemsRef.listAll();
    final items = await Future.wait(listResult.items.map((itemRef) async {
      final url = await itemRef.getDownloadURL();
      final colorCategory = await getColorCategoryFromImage(url);
      return {'url': url, 'category': category, 'colorCategory': colorCategory.toString().split('.').last};
    }));
    return items.isNotEmpty ? items[(items.length * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000).floor()] : null;
  }

  Future<ColorCategory> getColorCategoryFromImage(String imageUrl) async {
    final ImageProvider imageProvider = NetworkImage(imageUrl);
    final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(imageProvider);
    return _mapColorToCategory(palette.dominantColor?.color ?? Colors.white);
  }

  ColorCategory _mapColorToCategory(Color color) {
    if ((color.red > 200 && color.green > 200 && color.blue > 200) || (color.red < 50 && color.green < 50 && color.blue < 50)) {
      return ColorCategory.neutral;
    } else if ((color.red > color.green) && (color.red > color.blue)) {
      return ColorCategory.warm;
    } else {
      return ColorCategory.cool;
    }
  }

  Future<void> shuffleOutfits() async {
    setState(() {
      isShuffling = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favoritesRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites');
    final favoriteSnapshot = await favoritesRef.get();
    final favoriteCount = favoriteSnapshot.size;

    final name = favoriteName.isNotEmpty ? favoriteName : 'Fit ${favoriteCount + 1}';
    final Map<String, dynamic> outfitItems = Provider.of<ShuffleProvider>(context, listen: false).outfitItems;

    var itemsToSave = outfitItems.map((key, value) {
      if (value is Map<String, dynamic> && value.containsKey('colorCategory')) {
        var newValue = Map.of(value); // Clone the value map
        newValue['colorCategory'] = newValue['colorCategory'].toString().split('.').last; // Convert enum to string
        return MapEntry(key, newValue);
      }
      return MapEntry(key, value);
    });

    await favoritesRef.add({
      ...itemsToSave,
      'name': name,
      'dateSaved': DateTime.now(),
    }).then((value) {
      print("Outfit saved successfully.");
    }).catchError((error) {
      print("Failed to save outfit: $error");
    });

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
                    item['url'],
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
                      alignment: Alignment.center,  // Center-aligns the Column with clothing items
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
                    onPressed: saveToFavorites,
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
