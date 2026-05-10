class ArticlesModel {
  String id, title, date, image, name, description, category;

  ArticlesModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.description,
    required this.image,
    required this.name,
  });

  factory ArticlesModel.fromJson(Map<String, dynamic> json) {
    return ArticlesModel(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      date: json['date'],
      description: json['description'],
      image: json['image'],
      name: json['name'],
    );
  }
}
