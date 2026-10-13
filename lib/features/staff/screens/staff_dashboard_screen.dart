import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:str/core/database/app_database.dart';
import 'package:str/features/staff/providers/staff_provider.dart';
import 'package:str/features/staff/screens/waiter_view.dart';
import 'package:str/features/staff/screens/kitchen_view.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final orders = ref.watch(kitchenOrdersProvider);
    final reservations = ref.watch(reservationProvider);

    // Kiểm tra xem nhân viên đang đăng nhập thuộc bộ phận Bếp hay Phục vụ
    final subRole = (currentUser?.subRole ?? '').toLowerCase();
    final bool isKitchenStaff = subRole.contains('bếp') || subRole.contains('kitchen') || subRole.contains('bar');

    // Đếm số món nấu xong chờ Phục vụ bưng ra
    int readyToServeCount = 0;
    for (final o in orders) {
      for (final item in o.items) {
        if (item.status == DishStatus.ready) readyToServeCount++;
      }
    }

    // Đếm số đơn đặt bàn mới của Khách đang chờ Phục vụ xếp bàn
    final int pendingBookingCount = reservations.where((r) => r.status == 'PENDING').length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKitchenStaff ? 'Màn hình Nhà Bếp (KDS)' : 'Màn hình Nhân viên Phục vụ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (currentUser != null)
              Text(
                'NV: ${currentUser.name} (${currentUser.subRole})',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: isKitchenStaff ? Colors.deepOrange[800] : Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => context.pushReplacement('/'),
          )
        ],
      ),
      // Tách hoàn toàn giao diện theo chức vụ của nhân viên
      body: isKitchenStaff
          ? const KitchenView()
          : WaiterView(
              readyToServeCount: readyToServeCount,
              pendingBookingCount: pendingBookingCount,
            ),
    );
  }
}