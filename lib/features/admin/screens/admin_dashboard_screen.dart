import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:str/core/database/app_database.dart';
import 'package:str/features/staff/providers/staff_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. LẤY THÔNG TIN TÀI KHOẢN ADMIN ĐANG ĐĂNG NHẬP
    final currentUser = ref.watch(currentUserProvider);
    final myRestaurantName = currentUser?.restaurantName ?? 'Quản lý Hệ thống';

    final orders = ref.watch(kitchenOrdersProvider);
    
    // 2. LỌC DỮ LIỆU ĐỘC LẬP (CHỈ LẤY CỦA NHÀ HÀNG NÀY)
    final myMenuItems = ref.watch(menuDbProvider)
        .where((m) => m.restaurantName == myRestaurantName)
        .toList();
        
    // Tính luôn cả các tài khoản Phục vụ và Đầu bếp của nhà hàng này
    final staffCount = ref.watch(accountsDbProvider)
        .where((u) => 
            (u.role == 'STAFF' || u.role == 'WAITER' || u.role == 'CHEF') && 
            u.restaurantName == myRestaurantName)
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng quan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
            Text(
              myRestaurantName, // Hiển thị tên Nhà hàng chuẩn
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () => context.pushReplacement('/'),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hoạt động hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Stats Grid
            Row(
              children: [
                _buildStatCard(
                  title: 'Bàn đang phục vụ',
                  value: '${orders.length}', // Số lượng bàn đang có đơn trong bếp
                  subtitle: 'Real-time',
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Thực đơn',
                  value: '${myMenuItems.length}', // Đã lọc theo nhà hàng
                  subtitle: '${myMenuItems.where((m) => m.isAvailable).length} đang bán',
                  icon: Icons.restaurant_menu,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  title: 'Nhân sự',
                  value: '$staffCount', // Đã lọc theo nhà hàng
                  subtitle: 'Tài khoản Staff',
                  icon: Icons.people_alt,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Doanh thu tạm',
                  value: '---', 
                  subtitle: 'Chưa chốt ca',
                  icon: Icons.account_balance_wallet,
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text('Tính năng Quản trị', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Action Tiles
            _buildActionTile(
              context,
              title: 'Cài đặt Cửa hàng',
              subtitle: 'Địa chỉ, Bản đồ, Giờ mở cửa',
              icon: Icons.storefront,
              color: Colors.redAccent,
              route: '/admin/settings',
            ),
            _buildActionTile(
              context,
              title: 'Quản lý Nhân sự',
              subtitle: 'Thêm/Xóa tài khoản Phục vụ, Bếp',
              icon: Icons.badge,
              color: Colors.blue,
              route: '/admin/staff',
            ),
            _buildActionTile(
              context,
              title: 'Quản lý Thực đơn',
              subtitle: 'Thêm món, Sửa giá, Báo hết món',
              icon: Icons.menu_book,
              color: Colors.green,
              route: '/admin/menu',
            ),
            _buildActionTile(
              context, 
              title: 'Mã QR Đặt bàn', 
              subtitle: 'Tạo mã QR cho Khách tự quét gọi món',
              icon: Icons.qr_code_2_rounded, 
              color: Colors.purple, 
              route: '/admin/qr'
            ),
            _buildActionTile(
              context,
              title: 'Tin nhắn Khách hàng',
              subtitle: 'Tư vấn đặt bàn & Hỗ trợ trực tuyến',
              icon: Icons.forum_rounded,
              color: const Color(0xFFFF5722),
              route: '/admin/chat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required String subtitle, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required String route}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => context.push(route),
      ),
    );
  }
}