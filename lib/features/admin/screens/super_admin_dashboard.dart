import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:str/core/database/app_database.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRestaurants = ref.watch(realRestaurantListProvider);
    
    // Lọc ra các nhà hàng đang chờ duyệt
    final pendingList = allRestaurants.where((r) => r.status == 'PENDING').toList();
    // Lọc các nhà hàng đã duyệt để quản lý
    final approvedList = allRestaurants.where((r) => r.status == 'APPROVED').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hệ thống Quản trị', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1D26), fontSize: 18)),
            Text('Tài khoản: Super Admin', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            onPressed: () => context.pushReplacement('/'), // Đăng xuất
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStatCard('Chờ duyệt', pendingList.length, Colors.orange),
                  const SizedBox(width: 16),
                  _buildStatCard('Đang hoạt động', approvedList.length, Colors.green),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Danh sách yêu cầu phê duyệt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: pendingList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('Không có yêu cầu duyệt mới nào.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: pendingList.length,
                      itemBuilder: (context, index) {
                        final res = pendingList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.storefront_rounded, color: Color(0xFFFF5722)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(res.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('📍 Địa chỉ: ${res.address}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('📞 Chủ quán: ${res.ownerPhone}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('📋 Thể loại: ${res.category}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                      onPressed: () async {
                                        final success = await ref.read(realRestaurantListProvider.notifier).changeRestaurantStatus(res.id, 'REJECTED');
                                        if (context.mounted) {
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối nhà hàng!'), backgroundColor: Colors.red));
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Không thể từ chối. Hãy kiểm tra lại SQL!'), backgroundColor: Colors.orange));
                                          }
                                        }
                                      },
                                      child: const Text('TỪ CHỐI'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      onPressed: () async {
                                        final success = await ref.read(realRestaurantListProvider.notifier).changeRestaurantStatus(res.id, 'APPROVED');
                                        if (context.mounted) {
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phê duyệt thành công!'), backgroundColor: Colors.green));
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Không thể phê duyệt. Hãy kiểm tra lại SQL!'), backgroundColor: Colors.red));
                                          }
                                        }
                                      },
                                      child: const Text('PHÊ DUYỆT'),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: color, width: 4)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}