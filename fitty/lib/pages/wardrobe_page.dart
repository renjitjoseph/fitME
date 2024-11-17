// pages/wardrobe_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import 'upload_dialog.dart';
import 'favorites_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/pinata_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WardrobePage extends StatefulWidget {
  @override
  _WardrobePageState createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _uploadSuccessMessage;
  final PinataService _pinataService = PinataService();
  String? wardrobeDataCid;

  @override
  void initState() {
    super.initState();
    loadWardrobeDataCid();
    fetchWardrobeItems();
  }

  Future<void> loadWardrobeDataCid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      wardrobeDataCid = prefs.getString('wardrobeDataCid');
    });
  }

  Future<void> saveWardrobeDataCid(String cid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('wardrobeDataCid', cid);
    setState(() {
      wardrobeDataCid = cid;
    });
  }

  Future<void> fetchWardrobeItems() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final wardrobeProvider =
        Provider.of<WardrobeProvider>(context, listen: false);

    if (wardrobeDataCid == null) {
      // No wardrobe data available
      return;
    }

    Map<String, dynamic>? wardrobeData =
        await _pinataService.getJson(wardrobeDataCid!);

    if (wardrobeData != null) {
      wardrobeProvider.setWardrobeItemsFromJson(wardrobeData);
    }
  }

  Future<void> _handleUploadComplete(
      Map<String, String> uploadPayload, File image) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String category = uploadPayload['category']!;
    String? imageCid = await _pinataService.uploadFile(
      image,
      name: uploadPayload['subcategory'],
      keyValues: uploadPayload,
    );

    if (imageCid != null) {
      Map<String, dynamic> newItem = {
        'cid': imageCid,
        ...uploadPayload,
      };

      Provider.of<WardrobeProvider>(context, listen: false)
          .addWardrobeItem(category, newItem);

      // Fetch existing wardrobe data
      Map<String, dynamic> wardrobeData = {};
      if (wardrobeDataCid != null) {
        Map<String, dynamic>? existingData =
            await _pinataService.getJson(wardrobeDataCid!);
        if (existingData != null) {
          wardrobeData = existingData;
        }
      }

      // Update wardrobe data
      if (!wardrobeData.containsKey(category)) {
        wardrobeData[category] = [];
      }
      wardrobeData[category].add(newItem);

      // Upload updated wardrobe data
      String? newWardrobeDataCid = await _pinataService.uploadJson(
        wardrobeData,
        name: 'wardrobeData.json',
      );

      if (newWardrobeDataCid != null) {
        await saveWardrobeDataCid(newWardrobeDataCid);
        setState(() {
          _uploadSuccessMessage = 'Image uploaded successfully in $category';
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to upload image.'),
      ));
    }
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

  Future<void> deleteFile(String category, String cid) async {
    await _pinataService.deleteFile(cid);

    Provider.of<WardrobeProvider>(context, listen: false)
        .removeWardrobeItemByCid(category, cid);

    // Update wardrobe data
    Map<String, dynamic> wardrobeData = {};
    if (wardrobeDataCid != null) {
      Map<String, dynamic>? existingData =
          await _pinataService.getJson(wardrobeDataCid!);
      if (existingData != null) {
        wardrobeData = existingData;
      }
    }

    if (wardrobeData.containsKey(category)) {
      wardrobeData[category]
          .removeWhere((item) => item['cid'] == cid);
    }

    // Upload updated wardrobe data
    String? newWardrobeDataCid = await _pinataService.uploadJson(
      wardrobeData,
      name: 'wardrobeData.json',
    );

    if (newWardrobeDataCid != null) {
      await saveWardrobeDataCid(newWardrobeDataCid);
      setState(() {
        _uploadSuccessMessage = 'Item deleted successfully from $category';
      });
    }
  }

  Widget buildCategory(String category) {
    final items =
        Provider.of<WardrobeProvider>(context).wardrobeItems[category] ?? [];
    final isExpanded =
        Provider.of<WardrobeProvider>(context).expandedCategories[category] ??
            false;

    return ExpansionTile(
      title: Text(category),
      initiallyExpanded: isExpanded,
      onExpansionChanged: (bool expanded) {
        Provider.of<WardrobeProvider>(context, listen: false)
            .toggleCategoryExpansion(category);
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
                    'https://gateway.pinata.cloud/ipfs/${item['cid']}',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteFile(category, item['cid']);
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  'https://gateway.pinata.cloud/ipfs/${item['cid']}',
                  width: 100,
                  height: 100,
                ),
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
      length: 2, // Two tabs: Wardrobe and Favorites
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
            // Wardrobe Tab Content
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
                    children:
                        Provider.of<WardrobeProvider>(context)
                            .wardrobeItems
                            .keys
                            .map((category) {
                      return buildCategory(category);
                    }).toList(),
                  ),
                ),
              ],
            ),
            FavoritesTab(),
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
