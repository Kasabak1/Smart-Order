import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR tại bàn')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_isScanned) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _isScanned = true);
                  // Giả sử QR code chứa String ID của bàn, ví dụ: "TABLE_05"
                  final tableId = barcode.rawValue!;
                  
                  // Điều hướng sang màn hình Menu và truyền ID bàn
                  context.pushReplacementNamed('menu', pathParameters: {'tableId': tableId});
                  break;
                }
              }
            },
          ),
          // Vẽ khung vuông overlay để hướng dẫn người dùng quét
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        ],
      ),
    );
  }
}