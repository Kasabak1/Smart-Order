// lib/screens/staff_kds_screen.dart
import 'package:flutter/material.dart';

import '../models/mock_data.dart';
import 'table_menu_screen.dart';

class StaffKdsScreen extends StatefulWidget {
  const StaffKdsScreen({super.key});

  @override
  State<StaffKdsScreen> createState() => _StaffKdsScreenState();
}

class _StaffKdsScreenState extends State<StaffKdsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Tạo nhanh đơn mẫu nếu danh sách đang trống để tiện Demo
  void _seedSampleOrders() {
    setState(() {
      activeOrders.addAll([
        OrderItem(
          id: 'ord_1',
          dish: mockMenu[0],
          quantity: 2,
          note: 'Ít cay, cắt nhỏ',
          status: 'PENDING',
        ),
        OrderItem(
          id: 'ord_2',
          dish: mockMenu[2],
          quantity: 1,
          note: 'Không hành',
          status: 'COOKING',
        ),
        OrderItem(
          id: 'ord_3',
          dish: mockMenu[5],
          quantity: 4,
          note: 'Ít đá',
          status: 'READY',
        ),
      ]);
      // Đánh dấu Bàn 03 đang có khách ngồi
      mockTables[2].status = 'OCCUPIED';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã nạp 3 món ăn mẫu vào hệ thống KDS!'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'COOKING':
        return Colors.blue.shade700;
      case 'READY':
        return Colors.purple.shade700;
      case 'SERVED':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readyCount = activeOrders
        .where((o) => o.status == 'READY')
        .length;
    final pendingOrCookingCount = activeOrders
        .where((o) => o.status == 'PENDING' || o.status == 'COOKING')
        .length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF1E293B,
        ), // Màu tối chuyên nghiệp cho hệ thống Staff/KDS
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PHÂN HỆ NHÂN VIÊN & KDS BẾP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Đồng bộ thời gian thực (Socket Realtime)',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _seedSampleOrders,
            icon: const Icon(
              Icons.bolt,
              color: Colors.amber,
              size: 18,
            ),
            label: const Text(
              'Nạp đơn mẫu',
              style: TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF5722),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: pendingOrCookingCount > 0,
                label: Text('$pendingOrCookingCount'),
                child: const Icon(Icons.soup_kitchen_outlined),
              ),
              text: 'Màn hình Bếp - KDS (UC12)',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: readyCount > 0,
                backgroundColor: Colors.purpleAccent,
                label: Text('$readyCount'),
                child: const Icon(Icons.tablet_mac_outlined),
              ),
              text: 'Tablet Phục vụ (UC13-UC18)',
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildKitchenKdsTab(),
              _buildWaiterTabletTab(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: MÀN HÌNH KDS DÀNH CHO NHÂN VIÊN BẾP (UC12 & UC13)
  // =========================================================================
  Widget _buildKitchenKdsTab() {
    final kitchenOrders = activeOrders
        .where((o) => o.status != 'SERVED')
        .toList();

    if (kitchenOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 72,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            const Text(
              'Bếp đã hoàn thành tất cả các món!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chưa có đơn hàng mới từ khách hàng.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _seedSampleOrders,
              icon: const Icon(Icons.add),
              label: const Text('Tạo nhanh đơn hàng mẫu để Test KDS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Thanh thông báo chuông KDS
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          color: Colors.amber.shade100,
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: Colors.deepOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🔔 Màn hình KDS: Có ${kitchenOrders.length} món cần chế biến tại $currentActiveTable ($currentActiveRestaurant)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kitchenOrders.length,
            itemBuilder: (context, index) {
              final item = kitchenOrders[index];
              final statusColor = _getStatusColor(item.status);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: statusColor, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentActiveTable.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              item.status == 'PENDING'
                                  ? 'MỚI NHẬN (PENDING)'
                                  : item.status == 'COOKING'
                                  ? 'ĐANG NẤU (COOKING)'
                                  : 'CHỜ BƯNG RA BÀN (READY)',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: statusColor.withOpacity(
                              0.12,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.dish.imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Số lượng: ${item.quantity}x - ${item.dish.name}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.note.isNotEmpty
                                      ? '⚠️ Ghi chú của khách: "${item.note}"'
                                      : 'Không có ghi chú đặc biệt',
                                  style: TextStyle(
                                    color: item.note.isNotEmpty
                                        ? Colors.red.shade700
                                        : Colors.grey,
                                    fontWeight: item.note.isNotEmpty
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Các nút thao tác của Nhân viên Bếp theo đúng Activity Diagram
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.status == 'PENDING')
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(
                                  () => item.status = 'COOKING',
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        Colors.blue.shade700,
                                    content: Text(
                                      '👨‍🍳 Đã bấm "Bắt đầu nấu" món ${item.dish.name}. App khách đã đổi màu sang COOKING!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.local_fire_department,
                              ),
                              label: const Text(
                                'BẮT ĐẦU NẤU (COOKING)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          if (item.status == 'COOKING')
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() => item.status = 'READY');
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        Colors.purple.shade700,
                                    content: Text(
                                      '🔔 Món ${item.dish.name} đã SẴN SÀNG! Đã gửi Push Notification tới Tablet Phục vụ (UC13).',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.notifications_active,
                              ),
                              label: const Text(
                                'SẴN SÀNG PHỤC VỤ - READY (UC13)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.purple.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          if (item.status == 'READY')
                            const Text(
                              '✅ Đã báo Phục vụ đến quầy nhận món...',
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: MÀN HÌNH TABLET PHỤC VỤ (UC07, UC13, UC14, UC17, UC18)
  // =========================================================================
  Widget _buildWaiterTabletTab() {
    final readyOrders = activeOrders
        .where((o) => o.status == 'READY')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Khu vực nhận thông báo bưng món từ Bếp (UC13)
          const Row(
            children: [
              Icon(
                Icons.room_service_outlined,
                color: Color(0xFFFF5722),
              ),
              SizedBox(width: 8),
              Text(
                '1. Món ăn chờ mang ra bàn (UC13: Thông báo phục vụ món)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (readyOrders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Hiện không có món nào đang chờ tại quầy Bếp.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...readyOrders.map(
              (item) => Card(
                color: Colors.purple.shade50,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.purple.shade300),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.notifications_active),
                  ),
                  title: Text(
                    '[$currentActiveTable] ${item.quantity}x ${item.dish.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Bếp đã nấu xong • Hãy đến quầy nhận món mang ra bàn',
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => item.status = 'SERVED');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green.shade700,
                          content: Text(
                            '✅ Đã xác nhận "Đã phục vụ (SERVED)" món ${item.dish.name}!',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Đã phục vụ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          const Divider(height: 32),

          // 2. Nút mô phỏng System Timer tự động giải phóng bàn (UC07)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      color: Color(0xFFFF5722),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '2. Quản lý bàn trên Tablet (UC14, UC17, UC18)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  int releasedCount = 0;
                  setState(() {
                    for (var t in mockTables) {
                      if (t.status == 'BOOKED') {
                        t.status = 'AVAILABLE';
                        releasedCount++;
                      }
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.teal.shade700,
                      content: Text(
                        '⏱️ [System Timer - UC07] Đã tự động giải phóng $releasedCount bàn đặt trước quá 15 phút khách không đến!',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: const Text(
                  'Chạy System Timer (UC07)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Danh sách các bàn để Phục vụ thao tác
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.35,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
            itemCount: mockTables.length,
            itemBuilder: (context, index) {
              final table = mockTables[index];
              final isOccupied = table.status == 'OCCUPIED';
              final isBooked = table.status == 'BOOKED';

              Color badgeColor = isOccupied
                  ? Colors.red.shade600
                  : isBooked
                  ? Colors.amber.shade700
                  : Colors.green.shade600;

              String statusLabel = isOccupied
                  ? 'Đang ăn (OCCUPIED)'
                  : isBooked
                  ? 'Đã đặt (BOOKED)'
                  : 'Bàn trống (AVAILABLE)';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: badgeColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            table.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Sức chứa: ${table.seats} khách',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),

                      // Các nút chức năng của Phục vụ cho từng bàn
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // UC14: Gọi món hộ khách
                          ActionChip(
                            avatar: const Icon(
                              Icons.restaurant_menu,
                              size: 14,
                              color: Color(0xFFFF5722),
                            ),
                            label: const Text(
                              'Gọi món hộ (UC14)',
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              setState(() {
                                table.status = 'OCCUPIED';
                                currentActiveTable = table.name;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TableMenuScreen(
                                    restaurantName:
                                        currentActiveRestaurant,
                                    tableName: table.name,
                                  ),
                                ),
                              );
                            },
                          ),

                          // UC17 & UC18: Thu tiền mặt & Đóng phiên ăn giải phóng bàn
                          if (isOccupied || isBooked)
                            ActionChip(
                              backgroundColor: Colors.green.shade50,
                              avatar: const Icon(
                                Icons.payments_outlined,
                                size: 14,
                                color: Colors.green,
                              ),
                              label: const Text(
                                'Thu tiền & Trả bàn (UC17, 18)',
                                style: TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                setState(() {
                                  table.status = 'AVAILABLE';
                                  if (table.name ==
                                      currentActiveTable) {
                                    activeOrders.clear();
                                  }
                                });
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        Colors.green.shade700,
                                    content: Text(
                                      '💵 Đã xác nhận thu tiền mặt (UC17), đóng phiên ăn và giải phóng ${table.name} về trạng thái Trống (UC18)!',
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
