import 'package:flutter/material.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final _nameController = TextEditingController(text: 'Bếp Thái Koh Yam');
  final _addressController = TextEditingController(text: '122 Thái Hà, Đống Đa, Hà Nội');
  
  bool _isMapSelected = false; // Trạng thái đã ghim vị trí chưa

  @override
  Widget build(BuildContext context) {
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên cửa hàng', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Giờ mở cửa (VD: 08:00 - 22:00)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            
            const Text('VỊ TRÍ & BẢN ĐỒ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            
            // Khu vực mô phỏng Bản đồ (Map Placeholder)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
                image: const DecorationImage(
                  image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=21.012,105.819&zoom=15&size=600x300&maptype=roadmap'), // Ảnh map tĩnh giả lập
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!_isMapSelected)
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _isMapSelected = true);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật tọa độ GPS!')));
                          },
                          icon: const Icon(Icons.pin_drop),
                          label: const Text('Ghim vị trí hiện tại'),
                        ),
                      ),
                    ),
                  if (_isMapSelected)
                    const Icon(Icons.location_on, color: Colors.red, size: 50),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('(*) Tọa độ này giúp khách hàng tìm thấy quán của bạn trên bản đồ.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thông tin thành công!')));
                },
                child: const Text('LƯU THÔNG TIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}