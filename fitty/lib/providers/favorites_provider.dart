import 'package:flutter/foundation.dart';

class FavoritesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _favorites = [];

  List<Map<String, dynamic>> get favorites => _favorites;

  void setFavorites(List<Map<String, dynamic>> favorites) {
    _favorites = favorites;
    notifyListeners();
  }

  void addFavorite(Map<String, dynamic> favorite) {
    _favorites.add(favorite);
    notifyListeners();
  }

  void removeFavorite(String id) {
    _favorites.removeWhere((favorite) => favorite['id'] == id);
    notifyListeners();
  }
}
