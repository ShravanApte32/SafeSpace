// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hereforyou/screens/urgent_help_screen/emergency_contacts_screen.dart';
import 'package:hereforyou/utils/constants.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UrgentHelpPage extends StatelessWidget {
  const UrgentHelpPage({super.key});

  // Function to launch phone dialer
  void _callNumber(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  // Function to launch WhatsApp
  void _openWhatsApp(String phone, String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = "whatsapp://send?phone=$phone&text=$encodedMessage";

    if (await canLaunchUrlString(whatsappUrl)) {
      await launchUrlString(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      final fallbackUrl = "https://wa.me/$phone?text=$encodedMessage";
      if (await canLaunchUrlString(fallbackUrl)) {
        await launchUrlString(
          fallbackUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Allows normal back navigation
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF0F5),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // Calming animation
                Lottie.asset('assets/animations/lil_heart.json', height: 200),
                const SizedBox(height: 10),

                const Text(
                  "You're Not Alone",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "If you are feeling overwhelmed, reach out now. We're here to help.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // Call helpline card
                helpCard(
                  icon: Icons.phone,
                  title: "Call National Helpline",
                  subtitle: "Connect instantly with a trained counselor",
                  color: Colors.redAccent,
                  onTap: () =>
                      _callNumber("917020666430"), // Replace with real number
                ),

                const SizedBox(height: 12),

                // WhatsApp support card
                helpCard(
                  icon: Icons.chat_bubble,
                  title: "WhatsApp Support",
                  subtitle: "Chat with a mental health volunteer",
                  color: Colors.redAccent,
                  onTap: () => _openWhatsApp(
                    "917020666430",
                    "Hi, I need urgent help.",
                  ), // Correct international format
                ),

                const SizedBox(height: 12),

                // View contacts card
                helpCard(
                  icon: Icons.contacts,
                  title: "Manage Emergency Contacts",
                  subtitle: "Call or add your trusted contacts",
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyContactsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
