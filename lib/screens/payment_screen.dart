import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/mock_data.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String restaurantName;
  final String tableName;

  const PaymentScreen({
    super.key,
    required this.restaurantName,
    required this.tableName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int splitPeople = 1; // Số người chia bill (Split Bill)
  String paymentMethod =
      'ONLINE'; // 'ONLINE' (VNPay/MoMo) hoặc 'CASH' (Tiền mặt)
  String selectedWallet = 'VNPay'; // 'VNPay' hoặc 'MoMo'

  double get subtotal => activeOrders.fold(
    0,
    (sum, item) => sum + (item.dish.price * item.quantity),
  );
  double get vatAmount => subtotal * 0.08; // Thuế VAT 8%
  double get totalAmount => subtotal + vatAmount;
  double get amountPerPerson => totalAmount / splitPeople;

  // Xử lý hoàn tất thanh toán & Giải phóng bàn theo Activity Diagram
  void _completePaymentProcess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF5722)),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                paymentMethod == 'ONLINE'
                    ? 'Đang chờ Webhook xác nhận giao dịch từ $selectedWallet...'
                    : 'Đang gửi yêu cầu thu tiền mặt tới Tablet Phục vụ...',
              ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      // Giải phóng bàn về trạng thái Trống (AVAILABLE) và xóa đơn cũ
      setState(() {
        activeOrders.clear();
        sharedCart.clear();
        for (var t in mockTables) {
          if (t.name == widget.tableName) {
            t.status = 'AVAILABLE';
          }
        }
      });

      // Hiện thông báo Đóng hóa đơn (COMPLETED)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.verified_rounded,
            color: Colors.green,
            size: 64,
          ),
          title: const Text('Thanh toán thành công!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hóa đơn tại ${widget.tableName} đã được đóng (Status: COMPLETED).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔄 Hệ thống đã tự động giải phóng ${widget.tableName} về trạng thái TRỐNG (AVAILABLE).',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                ),
                child: const Text('VỀ TRANG CHỦ'),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        title: const Text('Thanh toán & Chia Bill (UC15, UC16)'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Tóm tắt hóa đơn
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                            Text(
                              widget.restaurantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: Text(
                                widget.tableName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor:
                                  Colors.deepOrange.shade50,
                            ),
                          ],
                        ),
                        const Divider(),
                        ...activeOrders.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x ${item.dish.name}',
                                  ),
                                ),
                                Text(
                                  formatCurrency(
                                    item.dish.price * item.quantity,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tạm tính:',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(formatCurrency(subtotal)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'VAT (8%):',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(formatCurrency(vatAmount)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TỔNG CỘNG:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatCurrency(totalAmount),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Tính năng Chia tiền - Split Bill (UC15)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.group_outlined,
                              color: Color(0xFFFF5722),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Chia tiền hóa đơn - Split Bill (UC15)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Số người chia đều:'),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: splitPeople > 1
                                      ? () => setState(
                                          () => splitPeople--,
                                        )
                                      : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                  ),
                                ),
                                Text(
                                  '$splitPeople người',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => splitPeople++),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFFFF5722),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mỗi người cần đóng:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${formatCurrency(amountPerPerson)} / người',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Chọn phương thức thanh toán (UC16)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phương thức thanh toán (UC16)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<String>(
                          value: 'ONLINE',
                          groupValue: paymentMethod,
                          activeColor: const Color(0xFFFF5722),
                          title: const Text(
                            'Thanh toán trực tuyến (QR VNPay / MoMo)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Quét mã QR trên App Ngân hàng hoặc Ví điện tử',
                          ),
                          onChanged: (val) =>
                              setState(() => paymentMethod = val!),
                        ),
                        RadioListTile<String>(
                          value: 'CASH',
                          groupValue: paymentMethod,
                          activeColor: const Color(0xFFFF5722),
                          title: const Text(
                            'Tiền mặt tại bàn / tại quầy',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Nhân viên phục vụ sẽ đến bàn thu tiền và xác nhận trên Tablet',
                          ),
                          onChanged: (val) =>
                              setState(() => paymentMethod = val!),
                        ),

                        if (paymentMethod == 'ONLINE') ...[
                          const Divider(),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('Cổng VNPay QR'),
                                selected: selectedWallet == 'VNPay',
                                selectedColor: Colors.blue.shade100,
                                onSelected: (_) => setState(
                                  () => selectedWallet = 'VNPay',
                                ),
                              ),
                              const SizedBox(width: 12),
                              ChoiceChip(
                                label: const Text('Ví MoMo QR'),
                                selected: selectedWallet == 'MoMo',
                                selectedColor: Colors.pink.shade100,
                                onSelected: (_) => setState(
                                  () => selectedWallet = 'MoMo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: selectedWallet == 'VNPay'
                                      ? Colors.blue
                                      : Colors.pink,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(
                                  16,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'MÃ QR THANH TOÁN $selectedWallet',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selectedWallet == 'VNPay'
                                          ? Colors.blue.shade800
                                          : Colors.pink.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  QrImageView(
                                    data:
                                        'SMART_ORDER|$selectedWallet|${widget.tableName}|${amountPerPerson.toInt()}',
                                    version: QrVersions.auto,
                                    size: 180.0,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Số tiền: ${formatCurrency(amountPerPerson)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    splitPeople > 1
                                        ? '(Đã chia cho $splitPeople người)'
                                        : '(Toàn bộ hóa đơn)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _completePaymentProcess,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    paymentMethod == 'ONLINE'
                        ? 'GIẢ LẬP QUÉT QR & NHẬN WEBHOOK THÀNH CÔNG'
                        : 'GỬI YÊU CẦU THU TIỀN MẶT TỚI PHỤC VỤ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
