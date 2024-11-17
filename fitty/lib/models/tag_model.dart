class Tag {
  final String name;

  Tag({required this.name});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      name: map['name'],
    );
  }
}
