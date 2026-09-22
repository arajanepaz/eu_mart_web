import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerWeb: WebDebugProvider(
      debugToken: '3d20be5e-0fdd-4dc8-a96b-2ac582819be0',
    ),
  );

  runApp(const EuMartWebApp());
}

class EuMartWebApp extends StatelessWidget {
  const EuMartWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EÜ MART',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const LoginScreen(),
    );
  }
}
