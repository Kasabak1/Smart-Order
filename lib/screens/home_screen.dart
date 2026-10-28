import 'package:flutter/material.dart';

import '../models/mock_data.dart';
import 'restaurant_detail_screen.dart';
import 'qr_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SMART ORDER',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Khám phá & Đặt bàn thông minh',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _currentIndex == 0
              ? _buildExploreTab()
              : _buildMyBookingsTab(),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QrScanScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          'Quét QR Gọi món (UC08)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(
              Icons.storefront,
              color: Color(0xFFFF5722),
            ),
            label: 'Nhà hàng (UC03)',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: myBookings
                  .where((b) => b.status == 'CONFIRMED')
                  .isNotEmpty,
              label: Text(
                '${myBookings.where((b) => b.status == 'CONFIRMED').length}',
              ),
              child: const Icon(Icons.calendar_month_outlined),
            ),
            selectedIcon: const Icon(
              Icons.calendar_month,
              color: Color(0xFFFF5722),
            ),
            label: 'Bàn đã đặt (UC06)',
          ),
        ],
      ),
    );
  }

  // Tab 1: Tìm kiếm & Danh sách nhà hàng (UC03)
  Widget _buildExploreTab() {
    final filteredList = mockRestaurants.where((r) {
      return r.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          r.address.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();

    return Column(
      children: [
        // Thanh tìm kiếm (UC03)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) =>
                setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Tìm nhà hàng, lẩu, nướng, địa chỉ...',
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFFFF5722),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),

        // Danh sách nhà hàng
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final res = filteredList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () async {
                    final booked = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RestaurantDetailScreen(restaurant: res),
                      ),
                    );
                    if (booked == true) {
                      setState(() => _currentIndex = 1); // Chuyển sang tab Lịch đặt bàn sau khi đặt xong
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.network(
                            res.imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(
                                  20,
                                ),
                              ),
                              child: Text(
                                'Còn ${res.availableTables} bàn trống',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    res.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      res.rating.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    res.address,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  final booked = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RestaurantDetailScreen(
                                            restaurant: res,
                                          ),
                                    ),
                                  );
                                  if (booked == true) {
                                    setState(() => _currentIndex = 1);
                                  }
                                },
                                child: const Text(
                                  'Xem sơ đồ bàn & Đặt chỗ',
                                ),
                              ),
                            ),
                          ],
                        ),
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

  // Tab 2: Quản lý đặt bàn & Hủy đặt bàn (UC06)
  Widget _buildMyBookingsTab() {
    if (myBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Bạn chưa có lịch đặt bàn nào',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myBookings.length,
      itemBuilder: (context, index) {
        final booking = myBookings[index];
        final isCancelled = booking.status == 'CANCELLED';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.restaurant.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        isCancelled ? 'Đã hủy' : 'Đã giữ chỗ',
                        style: TextStyle(
                          color: isCancelled
                              ? Colors.red.shade800
                              : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: isCancelled
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '🪑 Vị trí: ${booking.table.name} (${booking.guests} khách)',
                ),
                const SizedBox(height: 4),
                Text('⏰ Thời gian: ${booking.time}'),
                if (!isCancelled) ...[
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        // Xử lý Hủy đặt bàn (UC06)
                        setState(() {
                          booking.status = 'CANCELLED';
                          booking.table.status = 'AVAILABLE'; // Trả lại trạng thái bàn trống
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã hủy lịch đặt bàn thành công!',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Hủy đặt bàn (UC06)',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
