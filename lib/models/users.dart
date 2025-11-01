class User {
  final int id;
  final String username;
  final String email;
  final String password; // new field

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      password: json['password_hash'], // assuming API returns it
    );
  }
}
