import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/coldchain_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization warning/error: $e');
  }
  runApp(const ColdGuardApp());
}

class ColdGuardApp extends StatelessWidget {
  const ColdGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ColdChainProvider()..connect(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ColdGuard',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0D47A1),
            foregroundColor: Colors.white,
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}