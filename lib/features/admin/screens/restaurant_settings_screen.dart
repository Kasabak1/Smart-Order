import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str/core/database/app_database.dart';

// Đổi từ StatefulWidget sang ConsumerStatefulWidget để dùng Riverpod
class RestaurantSettingsScreen extends ConsumerStatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  ConsumerState<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends ConsumerState<RestaurantSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _timeController = TextEditingController(text: '08:00 - 22:00');
  
  LatLng _selectedLocation = const LatLng(21.028511, 105.804817); // Mặc định nếu chưa có
  final MapController _mapController = MapController();
  bool _isInit = false; // Dùng để chỉ nạp dữ liệu từ DB 1 lần duy nhất

  @override
  Widget build(BuildContext context) {
    // 1. Lấy thông tin chủ quán đang đăng nhập
    final currentUser = ref.watch(currentUserProvider);
    final allRes = ref.watch(realRestaurantListProvider);
    final myRes = allRes.where((r) => r.ownerPhone == currentUser?.phone).firstOrNull;

    // 2. Tự động điền dữ liệu thật (Tên, Địa chỉ, Tọa độ) từ DB vào giao diện lúc mới mở
    if (!_isInit && myRes != null) {
      _nameController.text = myRes.name;
      _addressController.text = myRes.address;
      _timeController.text = myRes.openTime;
      _selectedLocation = LatLng(myRes.lat, myRes.lng); // Lấy vị trí cũ đang lưu trên DB
      _isInit = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ Nhà hàng'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('THÔNG TIN CƠ BẢN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên cửa hàng', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _timeController, decoration: const InputDecoration(labelText: 'Giờ mở cửa (VD: 08:00 - 22:00)', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            
            const Text('VỊ TRÍ & BẢN ĐỒ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            
            const Text('Chạm vào bản đồ để ghim vị trí chính xác của quán:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[200]!)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15.0,
                    onTap: (tapPosition, latLng) {
                      setState(() => _selectedLocation = latLng);
                      _mapController.move(latLng, 15.0); // Di chuyển camera theo điểm chạm
                    },
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.smartorder.app'),
                    MarkerLayer(markers: [Marker(point: _selectedLocation, width: 50, height: 50, alignment: Alignment.topCenter, child: const Icon(Icons.location_on, color: Colors.red, size: 50))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('(*) Tọa độ này giúp khách hàng tìm thấy quán của bạn và được dùng để tính toán khoảng cách chỉ đường.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () async {
                  if (currentUser == null) return;
                  if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên và địa chỉ!'), backgroundColor: Colors.red));
                    return;
                  }

                  // 3. ĐẨY TỌA ĐỘ VÀ THÔNG TIN MỚI LÊN DB SUPABASE
                  final success = await ref.read(realRestaurantListProvider.notifier).submitStoreProfile(
                    currentUser.phone,
                    _nameController.text.trim(),
                    _addressController.text.trim(),
                    myRes?.category ?? 'Đang cập nhật',
                    _timeController.text.trim(),
                    _selectedLocation.latitude, // Tọa độ mới
                    _selectedLocation.longitude,
                  );

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật vị trí thành công! Quán đang chờ duyệt lại...'), backgroundColor: Colors.green));
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi lưu dữ liệu!'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('LƯU THÔNG TIN & TỌA ĐỘ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}