import 'package:flutter/material.dart';

class HelplinePage extends StatefulWidget {
  const HelplinePage({super.key});

  @override
  State<HelplinePage> createState() => _HelplinePageState();
}

class _HelplinePageState extends State<HelplinePage> {
  final List<Map<String, String>> _numbers = [
    // Keep these as placeholders — replace with trusted local contacts/orgs.
    {'name': 'Local Emergency', 'phone': '112'},
    {'name': 'Trusted Friend', 'phone': ''},
    {'name': 'Counselor', 'phone': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Helplines")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _numbers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = _numbers[i];
          return ListTile(
            leading: const Icon(Icons.call_rounded),
            title: Text(n['name']!),
            subtitle: Text(n['phone']!.isEmpty ? "Add number" : n['phone']!),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final c = TextEditingController(text: n['phone']);
                final newNum = await showDialog<String>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Edit ${n['name']}"),
                    content: TextField(
                      controller: c,
                      decoration: const InputDecoration(
                        hintText: "Enter phone number",
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, c.text.trim()),
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                );
                if (newNum != null) {
                  setState(() => _numbers[i]['phone'] = newNum);
                }
              },
            ),
            onTap: () {
              final phone = _numbers[i]['phone'] ?? '';
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Add a number first, then tap to call."),
                  ),
                );
                return;
              }
              // Use url_launcher if you want to actually dial:
              // launchUrl(Uri.parse("tel:$phone"));
            },
          );
        },
      ),
    );
  }
}
