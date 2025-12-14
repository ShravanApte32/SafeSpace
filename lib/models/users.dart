class User {
  final int id;
  final String username;
  final String email;
  final String password;
  final bool isGuest;
  final String country;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.isGuest,
    required this.country,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password_hash'] ?? '',
      isGuest: json['is_guest'] ?? false,
      country: json['country'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}
