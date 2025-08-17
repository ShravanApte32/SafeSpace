import 'package:flutter/material.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ("Grounding techniques", Icons.terrain),
      ("Healthy sleep tips", Icons.bedtime),
      ("Anxiety first-aid", Icons.healing),
      ("Emergency preparation", Icons.shield),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text("Resources")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (title, icon) = items[i];
          return ListTile(
            leading: Icon(icon),
            title: Text(title),
            tileColor: Colors.pink[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {},
          );
        },
      ),
    );
  }
}
