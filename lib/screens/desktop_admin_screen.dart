import 'package:flutter/material.dart';
import 'desktop_active_tables_view.dart';
import 'desktop_waiter_sales_view.dart';
import 'desktop_printer_setup_view.dart';
import 'desktop_menu_management_view.dart';

class DesktopAdminScreen extends StatefulWidget {
  const DesktopAdminScreen({super.key});

  @override
  State<DesktopAdminScreen> createState() => _DesktopAdminScreenState();
}

class _DesktopAdminScreenState extends State<DesktopAdminScreen> {
  int _selectedNavIndex = 2; // Default to Printer Setup / Ajustes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR NAVIGATION
          NavigationRail(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedNavIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF1E293B),
            selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
            unselectedIconTheme: const IconThemeData(color: Colors.white54, size: 24),
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Icon(Icons.point_of_sale, color: Colors.blueAccent, size: 40),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.table_restaurant_outlined),
                selectedIcon: Icon(Icons.table_restaurant),
                label: Text('Active Tables'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge),
                label: Text('Waiter Sales'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.print_outlined),
                selectedIcon: Icon(Icons.print),
                label: Text('Printer Setup'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: Text('Menu & Categories'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // MAIN WORKSPACE
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTabTitle(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildSelectedDesktopView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTabTitle() {
    switch (_selectedNavIndex) {
      case 0: return 'Active Tables Overview';
      case 1: return 'Waiter Sales & Performance';
      case 2: return 'Thermal Printers & Kitchen Settings';
      case 3: return 'Menu & Category Management';
      default: return 'POS Admin';
    }
  }

  Widget _buildSelectedDesktopView() {
    switch (_selectedNavIndex) {
      case 0:
        return const DesktopActiveTablesView();
      case 1:
        return const DesktopWaiterSalesView();
      case 2:
        return const DesktopPrinterSetupView();
      case 3:
        return const DesktopMenuManagementView();
      default:
        return const SizedBox.shrink();
    }
  }
}