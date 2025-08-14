// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hereforyou/data_source/fetch_users.dart';
import 'package:hereforyou/models/users.dart';
import 'package:hereforyou/screens/homepage/homepage_screen.dart';
import 'package:hereforyou/widgets/app_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();

      setState(() => _isLoading = true);

      try {
        final users = await fetchUsers();
        final user = users.firstWhere(
          (u) =>
              u.email.toLowerCase() == email.toLowerCase() &&
              u.password == password,
          orElse: () => User(id: 0, name: '', email: '', password: ''),
        );

        if (user.id != 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Welcome, ${user.name}!')));
          navigateWithLoader(context, HomePage(userName: user.name));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void navigateWithLoader(BuildContext context, Widget nextPage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppLoader(),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => nextPage));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4EC),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 80),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFEF9A9A)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your email';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(val)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                    onSaved: (val) => email = val!.trim(),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFEF9A9A)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFFEF9A9A),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (val.length < 6) {
                        return 'Password should be at least 6 characters';
                      }
                      return null;
                    },
                    onSaved: (val) => password = val!,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF9A9A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Color(0xFFEF9A9A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
