import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/feedback/public_feedback_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaEnterpriseProvider(
      '6LescbUtAAAAAJzW0rWO__Q5sokyUqkmcCEM91B3',
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

      // Keep text/layout predictable on narrow phone screens while still
      // respecting normal accessibility scaling.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final width = media.size.width;
        final currentScale = media.textScaler.scale(1.0);
        final cappedScale = width < 430 && currentScale > 1.15
            ? 1.15
            : currentScale;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(cappedScale)),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },

      // Default page of the EÜ MART system
      initialRoute: '/',

      // Application routes
      routes: {
        '/': (context) => const LoginScreen(),

        // Public page for customers who scan the feedback QR code
        '/feedback': (context) => const PublicFeedbackScreen(),
      },
    );
  }
}
