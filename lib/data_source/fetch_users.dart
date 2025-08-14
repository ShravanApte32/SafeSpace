import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/users.dart';

Future<List<User>> fetchUsers() async {
  final response = await http.get(
    Uri.parse('https://safespace-api-s.onrender.com/api/users'),
  );

  if (response.statusCode == 200) {
    List<dynamic> jsonData = json.decode(response.body);
    return jsonData.map((user) => User.fromJson(user)).toList();
  } else {
    throw Exception('Failed to load users');
  }
}
