import 'package:flutter/material.dart';

class ProfileTabPage extends StatelessWidget {
  final String userName;
  const ProfileTabPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Profile: $userName",
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
