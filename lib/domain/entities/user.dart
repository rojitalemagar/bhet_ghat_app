/// User entity representing a user in the domain layer
class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String? profileImageUrl;
  final String? gender;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.profileImageUrl,
    this.gender,
  });

  /// Create a copy of User with modified fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? profileImageUrl,
    String? gender,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, gender: $gender, profileImageUrl: $profileImageUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.password == password &&
        other.profileImageUrl == profileImageUrl &&
        other.gender == gender;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ email.hashCode ^ password.hashCode ^ profileImageUrl.hashCode ^ gender.hashCode;
  }
}