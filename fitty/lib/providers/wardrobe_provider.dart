// providers/wardrobe_provider.dart
import 'package:flutter/foundation.dart';

class WardrobeProvider with ChangeNotifier {
  Map<String, bool> _expandedCategories = {
    'top': false,
    'bottom': false,
    'shoes': false,
    'accessories': false,
  };

  Map<String, bool> get expandedCategories => _expandedCategories;

  Map<String, List<Map<String, dynamic>>> _wardrobeItems = {
    'top': [],
    'bottom': [],
    'shoes': [],
    'accessories': [],
  };

  Map<String, List<Map<String, dynamic>>> get wardrobeItems => _wardrobeItems;

  void toggleCategoryExpansion(String category) {
    _expandedCategories[category] = !_expandedCategories[category]!;
    notifyListeners();
  }

  void setWardrobeItems(String category, List<Map<String, dynamic>> items) {
    _wardrobeItems[category] = items;
    notifyListeners();
  }

  void setWardrobeItemsFromJson(Map<String, dynamic> data) {
    _wardrobeItems = data.map((key, value) {
      return MapEntry(key, List<Map<String, dynamic>>.from(value));
    });
    notifyListeners();
  }

  void addWardrobeItem(String category, Map<String, dynamic> item) {
    _wardrobeItems[category]?.add(item);
    notifyListeners();
  }

  void removeWardrobeItemByCid(String category, String cid) {
    _wardrobeItems[category]?.removeWhere((item) => item['cid'] == cid);
    notifyListeners();
  }
}
