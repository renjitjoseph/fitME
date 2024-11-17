import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/cached_data_provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.blue,  // Customize your AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Option 1'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Handle tap
              },
            ),
            ListTile(
              title: Text('Option 2'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Handle tap
              },
            ),
            ListTile(
              title: Text('Option 3'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Handle tap
              },
            ),
            ListTile(
              title: Text('Log Out'),
              trailing: Icon(Icons.logout),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                cachedDataProvider.clearData();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
