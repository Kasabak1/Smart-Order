import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false; 
  bool _isTorchOn = false; // Biến quản lý trạng thái đèn Flash

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return; 
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.contains('|')) {
        setState(() => _isScanned = true); 
        
        final parts = rawValue.split('|');
        final restaurantName = parts[0];
        final tableNumber = parts[1];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Nhận diện thành công: $tableNumber - $restaurantName'),
            backgroundColor: const Color(0xFF00C853),
            duration: const Duration(seconds: 1),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          context.pushReplacementNamed('menu', pathParameters: {
            'restaurantName': restaurantName,
            'tableId': tableNumber,
          });
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét mã QR tại bàn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            // Đã sửa lỗi: Dùng biến cục bộ thay cho ValueListenableBuilder
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off, 
              color: _isTorchOn ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF5722), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: -30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Đưa mã QR trên bàn vào khung này', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}