import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'followers_page.dart';
import 'following_page.dart';
import 'outfit_detail_page.dart';
import 'settings_page.dart';
import 'calendar_popup.dart';
import '../../providers/cached_data_provider.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User? user;
  bool _shouldShowCalendarPopup = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (!Provider.of<CachedDataProvider>(context, listen: false).dataFetched) {
      _fetchAllData();
    }
  }

  Future<void> _fetchAllData() async {
    await Provider.of<CachedDataProvider>(context, listen: false).fetchData();
  }

  Future<void> _uploadProfilePicture() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance.ref().child('profiles/${user!.uid}/profile.jpg');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await Provider.of<CachedDataProvider>(context, listen: false).updateProfileImageUrl(downloadUrl);

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'profileImageUrl': downloadUrl,
      });
    }
  }

  void _showOutfitDetails(Map<String, dynamic> outfit) {
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
                    outfit['name'] ?? 'Unnamed Outfit',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...['top', 'bottom', 'shoes', 'accessories'].map((category) {
                    final categoryData = outfit[category] as Map<String, dynamic>?; // Check for null
                    return categoryData != null && categoryData.containsKey('url')
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.toUpperCase(),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Image.network(
                                categoryData['url'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: 16),
                            ],
                          )
                        : Container(); // Return empty container if data is null or missing 'url'
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

  Future<void> _deleteSharedOutfit(String outfitId) async {
    await Provider.of<CachedDataProvider>(context, listen: false).deleteSharedOutfit(outfitId);
    // No need to fetch data again as real-time listener handles it
  }

  void _showCalendarPopup() async {
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) => CalendarPopup(),
    );

    if (selectedDate != null) {
      setState(() {
        _shouldShowCalendarPopup = true;  // Set the flag to reopen the calendar on back navigation
      });

      // Navigate to the outfit detail page and pass the outfitId instead of selectedDate
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutfitDetailPage(outfitId: "yourOutfitId"),
        ),
      );

      setState(() {
        _shouldShowCalendarPopup = false; // Reset the flag once back
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cachedDataProvider = Provider.of<CachedDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: _showCalendarPopup,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          // Reopen the calendar popup if it was open before navigating to the outfit detail page
          if (_shouldShowCalendarPopup) {
            _showCalendarPopup();
          }
          return true;  // Allow the back navigation
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _uploadProfilePicture,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: cachedDataProvider.profileImageUrl != null
                            ? NetworkImage(cachedDataProvider.profileImageUrl!)
                            : null,
                        child: cachedDataProvider.profileImageUrl == null
                            ? Icon(Icons.account_circle, size: 50)
                            : null,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      cachedDataProvider.userData != null && (cachedDataProvider.userData!.data() as Map<String, dynamic>?)?.containsKey('username') == true
                          ? cachedDataProvider.userData!['username']
                          : 'Username',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowersPage(userId: user!.uid),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text('${cachedDataProvider.followers.where((doc) => doc.id != user!.uid).length}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('followers'),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowingPage(userId: user!.uid),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text('${cachedDataProvider.following.where((doc) => doc.id != user!.uid).length}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('following'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to Edit Profile Page
                      },
                      child: Text('Edit profile'),
                    ),
                    SizedBox(height: 20),
                    Text('Shared Outfits:'),
                    Flexible(
                      fit: FlexFit.loose,
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: cachedDataProvider.sharedOutfits.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        itemBuilder: (context, index) {
                          final outfit = cachedDataProvider.sharedOutfits[index];
                          final outfitData = outfit.data() as Map<String, dynamic>?; // Check for null
                          return GestureDetector(
                            onTap: () {
                              if (outfitData != null) {
                                _showOutfitDetails(outfitData);
                              }
                            },
                            child: Card(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: GridView.builder(
                                      padding: EdgeInsets.all(4.0),
                                      itemCount: 4,
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                      ),
                                      itemBuilder: (context, idx) {
                                        String category;
                                        if (idx == 0) category = 'top';
                                        else if (idx == 1) category = 'bottom';
                                        else if (idx == 2) category = 'shoes';
                                        else category = 'accessories';

                                        final categoryData = outfitData?[category] as Map<String, dynamic>?; // Check for null
                                        return categoryData != null && categoryData.containsKey('url')
                                            ? Image.network(categoryData['url'])
                                            : Container();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(outfitData != null && outfitData.containsKey('name') ? outfitData['name'] : 'Unnamed'),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteSharedOutfit(outfit.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
