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
    notifyListeners();  // Ensures the UI updates immediately after the toggle
  }

  void setWardrobeItems(String category, List<Map<String, dynamic>> items) {
    _wardrobeItems[category] = items;
    notifyListeners();  // Ensures the UI updates immediately after setting items
  }

  void addWardrobeItem(String category, Map<String, dynamic> item) {
    _wardrobeItems[category]?.add(item);
    notifyListeners();  // Ensures the UI updates immediately after adding an item
  }

  void removeWardrobeItem(String category, String fileName) {
    _wardrobeItems[category]?.removeWhere((item) => item['fileName'] == fileName);
    notifyListeners();  // Ensures the UI updates immediately after removing an item
  }
}
