class TaskCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final List<String> subcategories;
  final bool isPopular;

  TaskCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.subcategories,
    this.isPopular = false,
  });

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    return TaskCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconName: json['iconName'],
      subcategories: List<String>.from(json['subcategories']),
      isPopular: json['isPopular'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'subcategories': subcategories,
      'isPopular': isPopular,
    };
  }
}
