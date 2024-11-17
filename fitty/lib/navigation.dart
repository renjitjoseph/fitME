import 'package:flutter/material.dart';
import '/pages/wardrobe_page.dart';
import '/pages/shuffle_page.dart';
import '/pages/favorites_page.dart';
import '/pages/profile_page/profile_page.dart';
import '/pages/feed_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Navigation extends StatefulWidget {
  const Navigation({Key? key}) : super(key: key);

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final storageRef = FirebaseStorage.instance.ref().child('profiles/${user.uid}/profile.jpg');
      try {
        final url = await storageRef.getDownloadURL();
        setState(() {
          _profileImageUrl = url;
        });
      } catch (e) {
        // Handle error if profile image does not exist
      }
    }
  }

  static final List<Widget> _pages = <Widget>[
    FeedPage(),
    WardrobePage(),
    ShufflePage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shuffle),
            label: 'Fit Me',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: _profileImageUrl != null
                ? CircleAvatar(
                    radius: 15,
                    backgroundImage: NetworkImage(_profileImageUrl!),
                  )
                : Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
