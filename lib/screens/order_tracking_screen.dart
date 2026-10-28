// lib/screens/order_tracking_screen.dart
import 'package:flutter/material.dart';

import '../models/mock_data.dart';
import 'payment_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String restaurantName;
  final String tableName;

  const OrderTrackingScreen({
    super.key,
    required this.restaurantName,
    required this.tableName,
  });

  @override
  State<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // Màu sắc tự động đổi theo trạng thái món (Activity Diagram)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange.shade700; // Đang chờ bếp xác nhận
      case 'COOKING':
        return Colors.blue.shade700; // Đang nấu
      case 'READY':
        return Colors.purple.shade700; // Sẵn sàng phục vụ
      case 'SERVED':
        return Colors.green.shade700; // Đã mang ra bàn
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận (PENDING)';
      case 'COOKING':
        return 'Đang chế biến (COOKING)';
      case 'READY':
        return 'Chờ mang ra bàn (READY)';
      case 'SERVED':
        return 'Đã phục vụ (SERVED)';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_top_rounded;
      case 'COOKING':
        return Icons.soup_kitchen_rounded;
      case 'READY':
        return Icons.notifications_active_rounded;
      case 'SERVED':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_outline;
    }
  }

  // Hàm giả lập sự kiện Socket từ Bếp/Phục vụ bắn về App Khách hàng
  void _simulateSocketUpdate(String newStatus) {
    setState(() {
      for (var order in activeOrders) {
        order.status = newStatus;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _getStatusColor(newStatus),
        duration: const Duration(seconds: 1),
        content: Text(
          '⚡ [Socket Realtime] Trạng thái món đã chuyển sang: ${_getStatusText(newStatus)}',
        ),
      ),
    );
  }

  double get totalOrderPrice => activeOrders.fold(
    0,
    (sum, item) => sum + (item.dish.price * item.quantity),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiến độ đơn hàng Realtime',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.restaurantName} • ${widget.tableName}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: activeOrders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có món nào được gửi xuống Bếp',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Bảng điều khiển giả lập Socket thời gian thực (Cực tiện khi Demo với Giảng viên)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        border: Border.all(
                          color: Colors.blueGrey.shade200,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.bolt,
                                color: Colors.amber,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Giả lập Socket Realtime từ Bếp & Phục vụ (Click để đổi màu món):',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(
                                  Icons.soup_kitchen,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  '1. Bếp bấm "Bắt đầu nấu"',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () =>
                                    _simulateSocketUpdate('COOKING'),
                              ),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.notifications_active,
                                  size: 16,
                                  color: Colors.purple,
                                ),
                                label: const Text(
                                  '2. Bếp bấm "Sẵn sàng"',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () =>
                                    _simulateSocketUpdate('READY'),
                              ),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                label: const Text(
                                  '3. Phục vụ bấm "Đã phục vụ"',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () =>
                                    _simulateSocketUpdate('SERVED'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Danh sách các món đã gọi kèm trạng thái đổi màu
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) {
                          final order = activeOrders[index];
                          final statusColor = _getStatusColor(
                            order.status,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: statusColor.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    child: Image.network(
                                      order.dish.imageUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${order.quantity}x ${order.dish.name}',
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (order.note.isNotEmpty)
                                          Text(
                                            'Ghi chú: ${order.note}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontStyle:
                                                  FontStyle.italic,
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Text(
                                          formatCurrency(
                                            order.dish.price *
                                                order.quantity,
                                          ),
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Huy hiệu trạng thái tự động đổi màu
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(
                                                  20,
                                                ),
                                          ),
                                          child: Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getStatusIcon(
                                                  order.status,
                                                ),
                                                size: 15,
                                                color: statusColor,
                                              ),
                                              const SizedBox(
                                                width: 6,
                                              ),
                                              Text(
                                                _getStatusText(
                                                  order.status,
                                                ),
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
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
                ),
        ),
      ),

      // Thanh Yêu cầu thanh toán ở đáy màn hình (UC15)
      bottomNavigationBar: activeOrders.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng tiền đơn hàng:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            formatCurrency(totalOrderPrice),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                restaurantName: widget.restaurantName,
                                tableName: widget.tableName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text(
                          'YÊU CẦU THANH TOÁN (UC15)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
