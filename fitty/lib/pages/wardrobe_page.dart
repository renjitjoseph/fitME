import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import 'upload_dialog.dart';

class WardrobePage extends StatefulWidget {
  @override
  _WardrobePageState createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _uploadSuccessMessage;

  @override
  void initState() {
    super.initState();
    fetchWardrobeItems();
  }

  Future<void> fetchWardrobeItems() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final wardrobeProvider = Provider.of<WardrobeProvider>(context, listen: false);

    final categories = wardrobeProvider.wardrobeItems.keys;
    for (final category in categories) {
      final itemsRef = _storage.ref().child('wardrobe/${user.uid}/$category');
      final listResult = await itemsRef.listAll();

      final items = await Future.wait(listResult.items.map((itemRef) async {
        final url = await itemRef.getDownloadURL();
        final fileName = itemRef.name;

        final docSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wardrobe')
            .doc(category)
            .collection('items')
            .where('fileName', isEqualTo: fileName)
            .limit(1)
            .get();

        Map<String, dynamic> data = {};
        if (docSnapshot.docs.isNotEmpty) {
          data = docSnapshot.docs.first.data();
        }

        return {
          ...data,
          'url': url,
          'fileName': fileName,
        };
      }).toList());

      wardrobeProvider.setWardrobeItems(category, items);
    }
  }

  Future<void> _handleUploadComplete(Map<String, String> uploadPayload, File image) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String category = uploadPayload['category']!;
    final String fileName = image.path.split('/').last;
    final Reference storageRef = _storage.ref().child('wardrobe/${user.uid}/$category/$fileName');

    final uploadTask = storageRef.putFile(image);
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    final updatedPayload = {
      ...uploadPayload,
      'url': downloadUrl,
      'fileName': fileName,
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wardrobe')
        .doc(category)
        .collection('items')
        .add(updatedPayload);

    Provider.of<WardrobeProvider>(context, listen: false)
        .addWardrobeItem(category, updatedPayload);

    setState(() {
      _uploadSuccessMessage = 'Image uploaded successfully in $category';
    });

    fetchWardrobeItems();
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UploadDialog(
          onUploadComplete: _handleUploadComplete,
        );
      },
    );
  }

  Future<void> deleteFile(String category, String fileName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final storageRef = _storage.ref().child('wardrobe/${user.uid}/$category/$fileName');
    await storageRef.delete();

    final querySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wardrobe')
        .doc(category)
        .collection('items')
        .where('fileName', isEqualTo: fileName)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    Provider.of<WardrobeProvider>(context, listen: false)
        .removeWardrobeItem(category, fileName);
  }

  Widget buildCategory(String category) {
    final items = Provider.of<WardrobeProvider>(context).wardrobeItems[category] ?? [];
    final isExpanded = Provider.of<WardrobeProvider>(context).expandedCategories[category] ?? false;

    return ExpansionTile(
      title: Text(category),
      initiallyExpanded: isExpanded,
      onExpansionChanged: (bool expanded) {
        Provider.of<WardrobeProvider>(context, listen: false).toggleCategoryExpansion(category);
      },
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () {
                _showItemDetailsDialog(item, category);
              },
              child: Stack(
                children: [
                  Image.network(
                    item['url'],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteFile(category, item['fileName']);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showItemDetailsDialog(Map<String, dynamic> item, String category) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Item Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(item['url'], width: 100, height: 100),
                SizedBox(height: 10),
                Text('Category: $category'),
                Text('Subcategory: ${item['subcategory'] ?? 'N/A'}'),
                Text('Color: ${item['color'] ?? 'N/A'}'),
                Text('Material: ${item['material'] ?? 'N/A'}'),
                Text('Style: ${item['style'] ?? 'N/A'}'),
                Text('Season: ${item['season'] ?? 'N/A'}'),
                Text('Fit: ${item['fit'] ?? 'N/A'}'),
                if (item['brand'] != null) Text('Brand: ${item['brand']}'),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Wardrobe'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Wardrobe'),
              Tab(text: 'Favorites'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                if (_uploadSuccessMessage != null)
                  Container(
                    color: Colors.green,
                    width: double.infinity,
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      _uploadSuccessMessage!,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    children: Provider.of<WardrobeProvider>(context).wardrobeItems.keys.map((category) {
                      return buildCategory(category);
                    }).toList(),
                  ),
                ),
              ],
            ),
            Center(child: Text('Favorites Page Content')),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showUploadDialog,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
