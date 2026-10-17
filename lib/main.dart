import 'package:flutter/material.dart';
import 'screens/login_screen.dart';          // Waiter Login Screen
import 'screens/desktop_admin_screen.dart'; // Desktop Admin View

void main() {
  runApp(const WaiterMobileApp());
}

class WaiterMobileApp extends StatelessWidget {
  const WaiterMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Set LoginScreen directly as home to test on Windows
      home: const LoginScreen(),

      // When ready to restore auto-detection, use:
      // home: (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS)
      //     ? const DesktopAdminScreen()
      //     : const LoginScreen(),
    );
  }
}