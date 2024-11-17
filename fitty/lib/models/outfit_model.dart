class Outfit {
  final String id;
  final String imageUrl;
  final String category;
  final String description;

  Outfit({required this.id, required this.imageUrl, required this.category, required this.description});

  factory Outfit.fromMap(Map<String, dynamic> data) {
    return Outfit(
      id: data['id'],
      imageUrl: data['imageUrl'],
      category: data['category'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'category': category,
      'description': description,
    };
  }
}
