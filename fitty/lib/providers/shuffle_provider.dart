import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ShuffleProvider with ChangeNotifier {
  Map<String, dynamic> outfitItems = {
    'top': null,
    'bottom': null,
    'shoes': null,
    'accessories': null,
  };

  Map<String, bool> locks = {
    'top': false,
    'bottom': false,
    'shoes': false,
    'accessories': false,
  };

  void toggleLock(String category) {
    locks[category] = !locks[category]!;
    notifyListeners();
  }

  void setAndLockItem(String category, Map<String, dynamic> item) {
    outfitItems[category] = item;
    locks[category] = true;
    notifyListeners();
  }

  Future<void> shuffleOutfits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final Map<String, dynamic> newItems = {};
    for (final category in outfitItems.keys) {
      if (!locks[category]!) {
        final itemsRef = FirebaseStorage.instance.ref().child('wardrobe/${user.uid}/$category');
        final listResult = await itemsRef.listAll();
        final items = await Future.wait(listResult.items.map((itemRef) async {
          final url = await itemRef.getDownloadURL();
          return {'url': url, 'category': category};
        }));
        newItems[category] = items.isNotEmpty ? items[(items.length * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000).floor()] : null;
      } else {
        newItems[category] = outfitItems[category];
      }
    }
    outfitItems = newItems;
    notifyListeners();
  }

  void updateOutfitItems(Map<String, dynamic> newItems) {
    outfitItems = newItems;
    notifyListeners();
  }
}
