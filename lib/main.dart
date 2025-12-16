import 'package:flutter/material.dart';
import 'package:hereforyou/screens/homepage/home/homepage_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hereforyou/screens/splash_screen/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔗 Initialize Supabase
  await Supabase.initialize(
    url: 'https://kioxvcygcdboahyhkvcq.supabase.co',
    anonKey: 'sb_publishable_RkZlvuZ4JZ0Jn9mujE4SHA_a3x0VVQL',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HereForYou',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(userName: ''),
    );
  }
}
