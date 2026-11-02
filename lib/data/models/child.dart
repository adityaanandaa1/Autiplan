import 'equality.dart';
import 'child_theme.dart';

class Child {
  const Child({
    required this.id,
    required this.name,
    required this.fullName,
    required this.age,
    required this.theme,
    required this.likes,
    required this.avoids,
  });

  final String id;
  final String name;
  final String fullName;
  final int age;
  final ChildTheme theme;
  final List<String> likes;
  final List<String> avoids;

  Child copyWith({
    String? id,
    String? name,
    String? fullName,
    int? age,
    ChildTheme? theme,
    List<String>? likes,
    List<String>? avoids,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      theme: theme ?? this.theme,
      likes: likes ?? this.likes,
      avoids: avoids ?? this.avoids,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fullName': fullName,
    'age': age,
    'theme': theme.name,
    'likes': likes,
    'avoids': avoids,
  };

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String,
      name: json['name'] as String,
      fullName: json['fullName'] as String,
      age: json['age'] as int,
      theme: ChildTheme.values.byName(json['theme'] as String),
      likes: List<String>.from(json['likes'] as List),
      avoids: List<String>.from(json['avoids'] as List),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Child &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          fullName == other.fullName &&
          age == other.age &&
          theme == other.theme &&
          listEq(likes, other.likes) &&
          listEq(avoids, other.avoids);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      fullName.hashCode ^
      age.hashCode ^
      theme.hashCode;
}
