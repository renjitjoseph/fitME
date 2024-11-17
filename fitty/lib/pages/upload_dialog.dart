// pages/upload_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadDialog extends StatefulWidget {
  final Function(Map<String, String>, File) onUploadComplete;

  UploadDialog({required this.onUploadComplete});

  @override
  _UploadDialogState createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  TextEditingController _brandController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubcategory;
  String? _selectedColor;
  String? _selectedMaterial;
  String? _selectedStyle;
  String? _selectedSeason;
  String? _selectedFit;

  final List<String> _categories = ["top", "bottom", "shoes", "accessories"];
  final Map<String, List<String>> _subcategories = {
    "top": ["T-shirt", "Button Down", "Blouse", "Sweater", "Jacket", "Tank Top", "Hoodie", "Cardigan", "Polo Shirt"],
    "bottom": ["Jeans", "Skirt", "Shorts", "Trousers", "Leggings", "Cargo Pants", "Capris"],
    "shoes": ["Sneakers", "Boots", "Sandals", "Heels", "Loafers", "Flip Flops", "Running Shoes", "Slippers"],
    "accessories": ["Hat", "Belt", "Scarf", "Watch", "Sunglasses", "Gloves", "Jewelry", "Backpack"],
  };
  final List<String> _colors = ["Red", "Blue", "Beige", "Black", "White", "Navy", "Green", "Multi-color", "Yellow", "Purple", "Brown", "Pink", "Grey"];
  final List<String> _materials = ["Cotton", "Denim", "Leather", "Polyester", "Wool", "Silk", "Linen", "Nylon", "Rayon", "Velvet"];
  final List<String> _styles = ["Casual", "Formal", "Sporty", "Vintage", "Chic", "Streetwear", "Bohemian", "Preppy", "Business Casual"];
  final List<String> _seasons = ["Summer", "Winter", "All-season", "Rainy", "Transitional", "Spring", "Autumn"];
  final List<String> _fits = ["Slim", "Regular", "Oversized", "Tailored", "Loose", "Relaxed", "Fitted"];

  bool _isButtonEnabled = false;

  void _updateFormValidity() {
    setState(() {
      _isButtonEnabled = _selectedCategory != null &&
          _selectedSubcategory != null &&
          _selectedColor != null &&
          _selectedMaterial != null &&
          _selectedStyle != null &&
          _selectedSeason != null &&
          _selectedFit != null;
    });
  }

  Future<void> _handleImageSourceSelection(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      final File image = File(pickedFile.path);

      // Create upload payload, ensuring non-null values
      var uploadPayload = {
        'category': _selectedCategory!,
        'subcategory': _selectedSubcategory!,
        'color': _selectedColor!,
        'material': _selectedMaterial!,
        'style': _selectedStyle!,
        'season': _selectedSeason!,
        'fit': _selectedFit!,
        'brand': _brandController.text.isNotEmpty ? _brandController.text : "No Brand",
      };

      // Call the onUploadComplete method to pass the data back to the WardrobePage
      widget.onUploadComplete(uploadPayload, image);

      // Close the dialog after image selection
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upload Image'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: Text('Select Category'),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _selectedSubcategory = null;
                  _updateFormValidity();
                });
              },
            ),
            SizedBox(height: 10),
            if (_selectedCategory != null)
              DropdownButtonFormField<String>(
                value: _selectedSubcategory,
                hint: Text('Select Subcategory'),
                items: _subcategories[_selectedCategory!]!.map((subcategory) {
                  return DropdownMenuItem(value: subcategory, child: Text(subcategory));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubcategory = value;
                    _updateFormValidity();
                  });
                },
              ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedColor,
              hint: Text('Select Color'),
              items: _colors.map((color) {
                return DropdownMenuItem(value: color, child: Text(color));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedColor = value;
                  _updateFormValidity();
                });
              },
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedMaterial,
              hint: Text('Select Material'),
              items: _materials.map((material) {
                return DropdownMenuItem(value: material, child: Text(material));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMaterial = value;
                  _updateFormValidity();
                });
              },
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedStyle,
              hint: Text('Select Style'),
              items: _styles.map((style) {
                return DropdownMenuItem(value: style, child: Text(style));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStyle = value;
                  _updateFormValidity();
                });
              },
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedSeason,
              hint: Text('Select Season'),
              items: _seasons.map((season) {
                return DropdownMenuItem(value: season, child: Text(season));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSeason = value;
                  _updateFormValidity();
                });
              },
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedFit,
              hint: Text('Select Fit'),
              items: _fits.map((fit) {
                return DropdownMenuItem(value: fit, child: Text(fit));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFit = value;
                  _updateFormValidity();
                });
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Enter Brand (optional)',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isButtonEnabled
                  ? () {
                      // Transition to the image selection options
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Select Image Source'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(Icons.camera_alt),
                                  title: Text('Take Photo'),
                                  onTap: () => _handleImageSourceSelection(ImageSource.camera),
                                ),
                                ListTile(
                                  leading: Icon(Icons.photo_library),
                                  title: Text('Choose from Gallery'),
                                  onTap: () => _handleImageSourceSelection(ImageSource.gallery),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  : null,
              child: Text('Continue to Image Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
