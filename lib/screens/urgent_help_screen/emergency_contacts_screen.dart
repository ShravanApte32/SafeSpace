import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final List<Map<String, String>> _defaultContacts = const [];

  // User added contacts stored here
  final List<Map<String, String>> _userContacts = [];

  Future<void> _callNumber(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  void _showAddContactDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String number = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFE4EC), // Light pink background
        title: const Text(
          "Add Emergency Contact",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        content: Form(
          key: _formKey,
          child: SizedBox(
            height: 160,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Contact Name",
                    labelStyle: const TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFEF9A9A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? "Enter name" : null,
                  onSaved: (val) => name = val!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    labelStyle: const TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFEF9A9A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, // only digits allowed
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Enter phone number";
                    }
                    if (val.trim().length != 10) {
                      return "Enter a valid phone number";
                    }
                    return null;
                  },
                  onSaved: (val) => number = val!.trim(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFFEF9A9A)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF9A9A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                _formKey.currentState!.save();
                setState(() {
                  _userContacts.add({"country": name, "number": number});
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allContacts = [..._defaultContacts, ..._userContacts];

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4EC), // Light pink background
      appBar: AppBar(
        title: const Text(
          "Emergency Contacts",
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFEF9A9A), // Matching button color
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        itemCount: allContacts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final contact = allContacts[index];
          final isUserContact = index >= _defaultContacts.length;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEF9A9A),
                child: Text(
                  contact["country"]!.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                contact["country"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                contact["number"]!,
                style: const TextStyle(color: Colors.black54),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, color: Color(0xFFEF9A9A)),
                    onPressed: () => _callNumber(contact["number"]!),
                    tooltip: 'Call',
                  ),
                  if (isUserContact)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: const Color(0xFFFFE4EC),
                            title: const Text(
                              'Delete Contact',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF9A9A),
                                fontSize: 20,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete "${contact["country"]}"?',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Color(0xFFEF9A9A)),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _userContacts.removeAt(
                                      index - _defaultContacts.length,
                                    );
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Delete',
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF9A9A),
        onPressed: _showAddContactDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
