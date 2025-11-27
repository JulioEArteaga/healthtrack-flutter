import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pantallas
import 'screens/login_screen.dart';
import 'screens/main_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthTrack',
      theme: ThemeData(
        primaryColor: const Color(0xFFA05252),
        scaffoldBackgroundColor: const Color(0xFFF6EDED),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFA05252),
          secondary: Color(0xFFE8B4B4),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFA05252),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFA05252),
        ),
      ),

      /// 🔐 Puerta de autenticación
      home: const AuthGate(),

      /// 🌍 Rutas globales
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainMenu(),
      },
    );
  }
}

/// 🔒 Controla si el usuario está logueado
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase aún cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Usuario NO logueado
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Usuario logueado
        return const MainMenu();
      },
    );
  }
}
