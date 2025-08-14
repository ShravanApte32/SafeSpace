class User {
  final int id;
  final String name;
  final String email;
  final String password; // new field

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'], // assuming API returns it
    );
  }
}
