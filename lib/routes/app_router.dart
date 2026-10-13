import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart'; 
import '../features/auth/screens/register_screen.dart';

import '../features/home/screens/main_dashboard_screen.dart';
import '../features/staff/screens/staff_dashboard_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
// THÊM 2 IMPORT MỚI NÀY:
import '../features/admin/screens/restaurant_settings_screen.dart';
import '../features/admin/screens/staff_management_screen.dart';

import '../features/ordering/screens/qr_scanner_screen.dart';
import '../features/ordering/screens/menu_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/customer', name: 'customerHome', builder: (context, state) => const MainDashboardScreen()),
      GoRoute(path: '/staff', name: 'staffHome', builder: (context, state) => const StaffDashboardScreen()),
      GoRoute(path: '/admin', name: 'adminHome', builder: (context, state) => const AdminDashboardScreen()),
      
      // THÊM 2 ROUTE NÀY VÀO DƯỚI ADMIN
      GoRoute(
        path: '/admin/settings',
        name: 'restaurantSettings',
        builder: (context, state) => const RestaurantSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/staff',
        name: 'staffManagement',
        builder: (context, state) => const StaffManagementScreen(),
      ),

      GoRoute(path: '/scan', name: 'scanQR', builder: (context, state) => const QrScannerScreen()),
      GoRoute(
        path: '/menu/:tableId',
        name: 'menu',
        builder: (context, state) {
          final tableId = state.pathParameters['tableId']!;
          return MenuScreen(tableId: tableId);
        },
      ),
    ],
  );
});