import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';          // Mobile / Phone Emulator Entry
import 'screens/desktop_admin_screen.dart'; // Windows Desktop Entry
import 'screens/desktop_kds_view.dart';      // KDS Direct Web View Entry
import 'services/navigation.dart';

void main() {
  runApp(const WaiterMobileApp());
}

class WaiterMobileApp extends StatelessWidget {
  const WaiterMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Detect if running as a Web App (Tablet / Browser)
    final bool isWeb = kIsWeb;

    // 2. Detect if running on Desktop OS (Windows / macOS)
    final bool isDesktop = !isWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return MaterialApp(
      navigatorKey: AppNavigation.navigatorKey,
      title: 'POS System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      // Handle URL path navigation for web requests (e.g. /cocina)
      onGenerateRoute: (settings) {
        // If web URL contains '/cocina', open KDS View directly
        if (settings.name == '/cocina' || Uri.base.path.contains('cocina')) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Kitchen Display System')),
              body: const DesktopKdsView(),
            ),
          );
        }
        return null;
      },

      // Fallback home screen when no route match is found
      home: isWeb
          ? (Uri.base.path.contains('cocina')
          ? const Scaffold(body: DesktopKdsView())
          : const LoginScreen())
          : (isDesktop ? const DesktopAdminScreen() : const LoginScreen()),
    );
  }
}