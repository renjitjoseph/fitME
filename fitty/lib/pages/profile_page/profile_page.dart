// pages/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/pinata_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PinataService _pinataService = PinataService();
  String? _profileImageCid;

  @override
  void initState() {
    super.initState();
    loadProfileImageCid();
  }

  Future<void> loadProfileImageCid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImageCid = prefs.getString('profileImageCid');
    });
  }

  Future<void> saveProfileImageCid(String cid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImageCid', cid);
    setState(() {
      _profileImageCid = cid;
    });
  }

  Future<void> _pickAndUploadProfileImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final File image = File(pickedFile.path);

      String? imageCid = await _pinataService.uploadFile(
        image,
        name: 'profile_image',
      );

      if (imageCid != null) {
        await saveProfileImageCid(imageCid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload profile image.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: user == null
          ? Center(child: Text('Not logged in'))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _profileImageCid != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                            'https://gateway.pinata.cloud/ipfs/$_profileImageCid'),
                      )
                    : CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                SizedBox(height: 20),
                Text(
                  user.email ?? 'No Email',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickAndUploadProfileImage,
                  child: Text('Upload Profile Image'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  child: Text('Logout'),
                ),
              ],
            ),
    );
  }
}
