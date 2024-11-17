import 'package:flutter/material.dart';
import 'package:fitty/models/tag_model.dart';
import 'package:provider/provider.dart';
import 'package:fitty/providers/shuffle_provider.dart';
import 'package:fitty/pages/shuffle_page.dart';

class ImageDetailDialog extends StatelessWidget {
  final String imageUrl;
  final Map<String, dynamic> itemDetails; // This should include tags and other details
  final String category;

  ImageDetailDialog({required this.imageUrl, required this.itemDetails, required this.category});

  void navigateToShufflePage(BuildContext context) {
    final provider = Provider.of<ShuffleProvider>(context, listen: false);
    provider.setAndLockItem(category, itemDetails);
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ShufflePage()));
  }

  @override
  Widget build(BuildContext context) {
    List<Tag> tags = [];
    if (itemDetails.containsKey('tags') && itemDetails['tags'] != null) {
      tags = (itemDetails['tags'] as List<dynamic>).map((tagData) => Tag.fromMap(tagData)).toList();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imageUrl),
            SizedBox(height: 10),
            Text('Category: $category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...itemDetails.entries.map((entry) {
              if (entry.key != 'tags' && entry.key != 'url') {
                return Text('${entry.key}: ${entry.value}');
              }
              return SizedBox.shrink();
            }).toList(),
            SizedBox(height: 10),
            if (tags.isNotEmpty) ...[
              Text('Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: tags.map((tag) => Chip(label: Text(tag.name))).toList(),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                navigateToShufflePage(context);
                Navigator.of(context).pop();
              },
              child: Text('Shuffle Outfits'),
            ),
          ],
        ),
      ),
    );
  }
}
