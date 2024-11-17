import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/wardrobe_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/shuffle_provider.dart';
import 'providers/cached_data_provider.dart';
import 'pages/login_page.dart';
import 'navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load environment variables
  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully.");
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WardrobeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ShuffleProvider()),
        ChangeNotifierProvider(create: (_) => CachedDataProvider()),
      ],
      child: MaterialApp(
        title: 'Fitty',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginPage(),
          '/navigation': (context) => Navigation(),
        },
      ),
    );
  }
}
