import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/main_dashboard_screen.dart';
import '../features/staff/screens/staff_dashboard_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/restaurant_settings_screen.dart';
import '../features/admin/screens/staff_management_screen.dart';
import '../features/admin/screens/menu_management_screen.dart';
import '../features/ordering/screens/qr_scanner_screen.dart';
import '../features/ordering/screens/menu_screen.dart';
import '../features/chat/chat_screen.dart';
import 'package:str/features/admin/screens/super_admin_dashboard.dart';

// THÊM IMPORT MÀN HÌNH QR
import '../features/admin/screens/qr_management_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/customer', name: 'customerHome', builder: (context, state) => const MainDashboardScreen()),
      GoRoute(path: '/staff', name: 'staffHome', builder: (context, state) => const StaffDashboardScreen()),
      GoRoute(path: '/admin', name: 'adminHome', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/settings', name: 'restaurantSettings', builder: (context, state) => const RestaurantSettingsScreen()),
      GoRoute(path: '/admin/staff', name: 'staffManagement', builder: (context, state) => const StaffManagementScreen()),
      GoRoute(path: '/admin/menu', name: 'menuManagement', builder: (context, state) => const MenuManagementScreen()),
      GoRoute(
        path: '/admin/chat', 
        name: 'adminChat', 
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Hộp thư Khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1D26), elevation: 0.5), 
          backgroundColor: const Color(0xFFF6F7FB), 
          body: const RestaurantChatListView(staffName: 'Quản lý Nhà hàng')
        )
      ),
      
      // THÊM ĐƯỜNG DẪN MỞ MÀN HÌNH QUẢN LÝ QR TẠI ĐÂY
      GoRoute(
        path: '/admin/qr', 
        name: 'qrManagement', 
        builder: (context, state) => const QrManagementScreen()
      ),

      GoRoute(path: '/scan', name: 'scanQR', builder: (context, state) => const QrScannerScreen()),
      GoRoute(
        path: '/menu/:restaurantName/:tableId',
        name: 'menu',
        builder: (context, state) {
          final restaurantName = state.pathParameters['restaurantName']!;
          final tableId = state.pathParameters['tableId']!;
          return MenuScreen(restaurantName: restaurantName, tableId: tableId);
        },

      ),
      GoRoute(path: '/super-admin', name: 'superAdminHome', builder: (context, state) => const SuperAdminDashboardScreen()),
    ],
  );
});