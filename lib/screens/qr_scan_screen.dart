
import 'package:flutter/material.dart';

import '../models/mock_data.dart';
import 'table_menu_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  String selectedRestaurant = mockRestaurants[0].name;
  String selectedTable = 'Bàn 03';

  final List<String> sampleTables = [
    'Bàn 01',
    'Bàn 03',
    'Bàn 05',
    'Bàn 08 (VIP)',
  ];

  void _simulateScanSuccess() {
    currentActiveRestaurant = selectedRestaurant;
    currentActiveTable = selectedTable;

    // Hiển thị loading xác thực Token bàn theo đúng Activity Diagram
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFFF5722)),
            SizedBox(width: 20),
            Expanded(
              child: Text('Đang xác thực Token bàn & Tải Menu...'),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.pop(context); // Đóng dialog loading
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TableMenuScreen(
            restaurantName: selectedRestaurant,
            tableName: selectedTable,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Quét mã QR tại bàn (UC08)'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Đưa camera vào mã QR đặt trên bàn ăn',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Khung ngắm Camera giả lập
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: const Color(0xFFFF5722),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_2_rounded,
                        size: 160,
                        color: Colors.white54,
                      ),
                      Positioned(
                        top: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Đang nhận diện mã QR...',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bảng giả lập chọn nhanh bàn để Demo trên Web/Chrome
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.developer_mode,
                            color: Color(0xFFFF5722),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Chế độ Demo nhanh (Giả lập quét QR)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRestaurant,
                        decoration: InputDecoration(
                          labelText: 'Nhà hàng đang ngồi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: mockRestaurants
                            .map(
                              (r) => DropdownMenuItem(
                                value: r.name,
                                child: Text(r.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedRestaurant = val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedTable,
                        decoration: InputDecoration(
                          labelText: 'Mã QR Bàn số',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: sampleTables
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedTable = val!),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _simulateScanSuccess,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text(
                          'GIẢ LẬP QUÉT MÃ QR THÀNH CÔNG',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
