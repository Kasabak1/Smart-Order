import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị Nhà hàng'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.pushReplacement('/'), // Đăng xuất
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tổng quan hôm nay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Doanh thu', '12.5M', Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('Đơn hàng', '48', Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.store, color: Colors.redAccent),
            title: const Text('Thông tin & Bản đồ Nhà hàng'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/admin/settings'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.blue),
            title: const Text('Quản lý Nhân viên (Cấp tài khoản)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/admin/staff'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restaurant_menu, color: Colors.green),
            title: const Text('Quản lý Thực đơn'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}