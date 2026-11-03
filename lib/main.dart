import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SenaiPontoApp());
}

class SenaiPontoApp extends StatelessWidget {
  const SenaiPontoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102A43);
    const teal = Color(0xFF087E8B);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SENAI Ponto',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          primary: navy,
          secondary: teal,
          surface: const Color(0xFFF7F9FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Não foi possível verificar a sessão.'),
              ),
            );
          }
          return snapshot.data == null
              ? const LoginScreen()
              : const HomeScreen();
        },
      ),
    );
  }
}
