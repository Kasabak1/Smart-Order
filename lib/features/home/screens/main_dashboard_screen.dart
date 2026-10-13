import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_provider.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildExploreTab(),
      _buildHistoryTab(),
      _buildProfileTab(),
    ];

    final List<String> titles = [
      'Khám phá Nhà hàng',
      'Lịch sử Đặt bàn',
      'Hồ sơ Cá nhân',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Quét QR tại bàn',
            onPressed: () => context.pushNamed('scanQR'),
          ),
        ],
      ),
      body: pages[_currentIndex],
      // Chỉ hiện nút Quét QR nổi ở Tab Khám phá cho đỡ vướng khi xem lịch sử/sửa thông tin
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed('scanQR'),
              backgroundColor: Colors.deepOrange,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text('Quét QR Gọi Món', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.orange,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Khám phá'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch sử đặt'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  // ==========================================
  // 1. TAB KHÁM PHÁ & ĐẶT BÀN
  // ==========================================
  Widget _buildExploreTab() {
    final restaurants = ref.watch(restaurantListProvider);
    final filteredList = restaurants
        .where((r) =>
            r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Thanh tìm kiếm
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Tìm nhà hàng, loại món ăn...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Danh sách Nhà hàng đối tác', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Danh sách thẻ nhà hàng
        ...filteredList.map((restaurant) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    color: Colors.orange[100],
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront, size: 60, color: Colors.deepOrange),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  restaurant.category,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text('${restaurant.rating} / 5.0', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(restaurant.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 4),
                            Expanded(child: Text(restaurant.address, style: TextStyle(color: Colors.grey[700]))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('Mở cửa: ${restaurant.openTime}', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Cho phép xem trước Menu của quán
                                  context.pushNamed('menu', pathParameters: {'tableId': 'XemTrước'});
                                },
                                icon: const Icon(Icons.menu_book),
                                label: const Text('Xem Menu'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _showBookingSheet(context, restaurant),
                                icon: const Icon(Icons.event_seat),
                                label: const Text('Đặt bàn'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 80), // Khoảng trống dưới cùng
      ],
    );
  }

  // Popup chọn thông tin Đặt bàn
  void _showBookingSheet(BuildContext context, Restaurant restaurant) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 19, minute: 0);
    int guests = 2;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đặt bàn: ${restaurant.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(restaurant.address, style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 24),

                  // Chọn ngày & giờ
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) setModalState(() => selectedDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: selectedTime);
                            if (picked != null) setModalState(() => selectedTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chọn số lượng khách
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số lượng khách:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: guests > 1 ? () => setModalState(() => guests--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$guests người', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () => setModalState(() => guests++),
                            icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ghi chú
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú thêm (VD: Có trẻ em, ngồi phòng lạnh...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
                        final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                        ref.read(reservationProvider.notifier).addReservation(
                              restaurant.name,
                              restaurant.address,
                              dateStr,
                              timeStr,
                              guests,
                              noteController.text.trim(),
                            );

                        Navigator.pop(context); // Đóng popup
                        setState(() => _currentIndex = 1); // Chuyển ngay sang tab Lịch sử
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đặt bàn thành công!'), backgroundColor: Colors.green),
                        );
                      },
                      child: const Text('XÁC NHẬN ĐẶT BÀN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 2. TAB LỊCH SỬ ĐẶT BÀN & HỦY BÀN
  // ==========================================
  Widget _buildHistoryTab() {
    final reservations = ref.watch(reservationProvider);
    final activeList = reservations.where((r) => r.status == 'CONFIRMED').toList();
    final cancelledList = reservations.where((r) => r.status == 'CANCELLED').toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(text: 'Đang đặt (${activeList.length})'),
                Tab(text: 'Đã hủy (${cancelledList.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildReservationList(activeList, isActive: true),
                _buildReservationList(cancelledList, isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(List<Reservation> list, {required bool isActive}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? Icons.event_available : Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              isActive ? 'Bạn chưa có lịch đặt bàn nào.' : 'Không có đơn đặt bàn nào bị hủy.',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item.restaurantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Đã xác nhận' : 'Đã hủy',
                        style: TextStyle(
                          color: isActive ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('📍 ${item.address}', style: TextStyle(color: Colors.grey[700])),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 18, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text('Ngày: ${item.date}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 18, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text('Giờ: ${item.time}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 18, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text('Số khách: ${item.guests} người', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('📝 Ghi chú: ${item.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
                if (isActive) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy đặt bàn'),
                      onPressed: () => _confirmCancelDialog(context, item),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmCancelDialog(BuildContext context, Reservation item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy bàn'),
        content: Text('Bạn có chắc chắn muốn hủy lịch đặt bàn tại "${item.restaurantName}" lúc ${item.time} ngày ${item.date} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(reservationProvider.notifier).cancelReservation(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã hủy lịch đặt bàn!'), backgroundColor: Colors.redAccent),
              );
            },
            child: const Text('Hủy bàn'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. TAB THÔNG TIN CÁ NHÂN & CHỈNH SỬA
  // ==========================================
  Widget _buildProfileTab() {
    final profile = ref.watch(userProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.orange,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Thành viên Hạng Vàng', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.blue),
                  title: const Text('Số điện thoại'),
                  subtitle: Text(profile.phone),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.redAccent),
                  title: const Text('Email'),
                  subtitle: Text(profile.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.green),
                  title: const Text('Địa chỉ'),
                  subtitle: Text(profile.address),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _showEditProfileDialog(context, profile),
              icon: const Icon(Icons.edit),
              label: const Text('CHỈNH SỬA THÔNG TIN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => context.pushReplacement('/'),
              icon: const Icon(Icons.logout),
              label: const Text('ĐĂNG XUẤT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile currentProfile) {
    final nameCtrl = TextEditingController(text: currentProfile.name);
    final phoneCtrl = TextEditingController(text: currentProfile.phone);
    final emailCtrl = TextEditingController(text: currentProfile.email);
    final addressCtrl = TextEditingController(text: currentProfile.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Địa chỉ', prefixIcon: Icon(Icons.location_on)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(userProfileProvider.notifier).updateProfile(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }
}