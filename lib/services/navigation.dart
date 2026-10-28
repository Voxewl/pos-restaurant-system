import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/order_taking_screen.dart';

class AppNavigation {
  /// Global navigator key for Context-less navigation if needed
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to Home Screen (Waiter Terminal) and reset stack
  static void goToHome(BuildContext context, {required String waiterName}) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(waiterName: waiterName),
      ),
          (route) => false,
    );
  }

  /// Navigate to Order Taking Screen
  static Future<void> goToOrderTaking(
      BuildContext context, {
        required String tableNumber,
        required int guestCount,
        required String waiterName,
      }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTakingScreen(
          tableNumber: tableNumber,
          guestCount: guestCount,
          waiterName: waiterName,
        ),
      ),
    );
  }

  /// Logout and clear backstack to LoginScreen
  static void goToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  /// Pop current top view (Modal, Screen, or Dialog)
  static void pop(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Reset navigation stack back to primary HomeScreen
  static void popToHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}