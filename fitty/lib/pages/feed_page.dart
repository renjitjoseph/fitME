import 'package:fitty/services/user_actions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/feed_service.dart';
import '../services/search_service.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Map<String, dynamic>> feedItems = [];
  List<String> following = [];
  final List<String> categories = ["top", "bottom", "shoes", "accessories"];
  final FeedService _feedService = FeedService();
  final SearchService _searchService = SearchService();
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    checkUserAndFetchData();
  }

  void checkUserAndFetchData() {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      fetchFollowingAndFeed();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'User is not authenticated. Please log in.';
      });
    }
  }

  Future<void> fetchFollowingAndFeed() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      following = await _feedService.fetchFollowing();
      final fetchedFeed = await _feedService.fetchFeed(following);
      setState(() {
        feedItems = fetchedFeed;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching feed: $e";
        isLoading = false;
      });
    }
  }

  void showOutfitDetails(Map<String, dynamic> outfit) {
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
                    outfit['name'] ?? 'No Name',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...categories.map((category) {
                    return outfit[category] != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Image.network(
                                outfit[category]['url'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: 16),
                            ],
                          )
                        : Container();
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

  String formatDate(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return "today";
    } else if (difference == 1) {
      return "yesterday";
    } else if (difference <= 6) {
      return "$difference days ago";
    } else {
      return DateFormat('MM-dd-yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(
                  _searchService.searchUsers,
                  (String userId) async {
                    await followUser(userId);
                    fetchFollowingAndFeed(); // Refresh the feed after following
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : buildFeedGrid(),
    );
  }

  Widget buildFeedGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 0.75,
        ),
        itemCount: feedItems.length,
        itemBuilder: (context, index) {
          final feedItem = feedItems[index];
          final imageUrl = feedItem['imageUrl'];

          return GestureDetector(
            onTap: () => showOutfitDetails(feedItem),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/fallback_image.png', // Replace with your local fallback image asset
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/fallback_image.png', // Fallback image for null URL
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(feedItem['userAvatar'] ?? 'https://via.placeholder.com/40'),
                            radius: 12,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feedItem['username'] ?? 'Unknown user',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.more_horiz, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class UserSearchDelegate extends SearchDelegate {
  final Future<List<Map<String, dynamic>>> Function(String) searchUsers;
  final Function(String) followUser;

  UserSearchDelegate(this.searchUsers, this.followUser);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(child: Text('No users found'));
        }
        final results = snapshot.data as List<Map<String, dynamic>>;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              title: Text(result['username']),
              trailing: ElevatedButton(
                onPressed: () {
                  followUser(result['id']);
                  close(context, null);
                },
                child: Text('Follow'),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
