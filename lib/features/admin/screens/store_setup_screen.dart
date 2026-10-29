import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:str/core/database/app_database.dart';

class StoreSetupScreen extends ConsumerStatefulWidget {
  const StoreSetupScreen({super.key});
  @override ConsumerState<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends ConsumerState<StoreSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '08:00 - 22:00');
  
  LatLng _selectedLocation = const LatLng(21.028511, 105.804817); 
  final MapController _mapController = MapController();
  bool _isInit = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const Scaffold();

    final allRes = ref.watch(realRestaurantListProvider);
    final myRes = allRes.where((r) => r.ownerPhone == currentUser.phone).firstOrNull;

    // Chỉ điền sẵn dữ liệu vào form 1 lần lúc mới mở màn hình
    if (!_isInit && myRes != null) {
      _nameCtrl.text = myRes.name;
      _addressCtrl.text = myRes.address;
      _categoryCtrl.text = myRes.category;
      _timeCtrl.text = myRes.openTime;
      _selectedLocation = LatLng(myRes.lat, myRes.lng);
      _isInit = true;
    }

    // Nếu quán mới hoàn toàn (chưa có hồ sơ)
    final isNewStore = myRes == null;
    final statusText = isNewStore ? 'Chưa thiết lập hồ sơ' : (myRes.status == 'APPROVED' ? 'Đã được duyệt' : (myRes.status == 'REJECTED' ? 'Bị từ chối' : 'Đang chờ duyệt...'));
    final statusColor = isNewStore ? Colors.blue : (myRes.status == 'APPROVED' ? Colors.green : (myRes.status == 'REJECTED' ? Colors.red : Colors.orange));
    final statusIcon = isNewStore ? Icons.info_outline : (myRes.status == 'APPROVED' ? Icons.check_circle : (myRes.status == 'REJECTED' ? Icons.cancel : Icons.pending_actions));

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ Nhà hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 12),
                  Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                ],
              ),
            ),
            if (isNewStore) ...[
              const SizedBox(height: 12),
              const Text('Vui lòng khai báo thông tin quán để Ban quản trị phê duyệt trước khi đi vào hoạt động.', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 20),
            
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tên nhà hàng', filled: true)),
            const SizedBox(height: 12),
            TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết', filled: true)),
            const SizedBox(height: 12),
            TextField(controller: _categoryCtrl, decoration: const InputDecoration(labelText: 'Danh mục (VD: Lẩu & Thái)', filled: true)),
            const SizedBox(height: 12),
            TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'Giờ hoạt động', filled: true)),
            
            const SizedBox(height: 24),
            const Text('Chạm vào bản đồ để cắm cờ vị trí quán:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Container(
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15.0,
                    onTap: (tapPosition, latLng) {
                      setState(() => _selectedLocation = latLng);
                      _mapController.move(latLng, 15.0); 
                    },
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.smartorder.app'),
                    MarkerLayer(markers: [Marker(point: _selectedLocation, width: 50, height: 50, alignment: Alignment.topCenter, child: const Icon(Icons.location_on, color: Colors.red, size: 50))]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () async {
                  if (_nameCtrl.text.isEmpty || _addressCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Tên và Địa chỉ!'), backgroundColor: Colors.red));
                    return;
                  }
                  final success = await ref.read(realRestaurantListProvider.notifier).submitStoreProfile(
                    currentUser.phone, _nameCtrl.text.trim(), _addressCtrl.text.trim(), _categoryCtrl.text.trim(), _timeCtrl.text.trim(), _selectedLocation.latitude, _selectedLocation.longitude
                  );
                  if (success && context.mounted) {
                    // Update current user state session locally to reflect the new restaurant name immediately
                    ref.read(currentUserProvider.notifier).state = currentUser.copyWith(restaurantName: _nameCtrl.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã Gửi yêu cầu duyệt thành công!'), backgroundColor: Colors.green));
                  }
                },
                child: const Text('LƯU & YÊU CẦU DUYỆT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}