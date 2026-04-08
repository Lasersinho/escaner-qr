import 'package:json_annotation/json_annotation.dart';

/// Domain model for an authenticated user.
@JsonSerializable()
class User {
  const User({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    required this.document,
  });

  final String id;
  final String name;
  final String lastname;
  final String email;
  final String document;

  String get fullName => [name, lastname].where((part) => part.trim().isNotEmpty).join(' ');

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['document'] as String,
        name: json['name'] as String,
        lastname: json['lastname'] as String,
        email: json['email'] as String,
        document: json['document'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lastname': lastname,
        'email': email,
        'document': document,
      };
}
