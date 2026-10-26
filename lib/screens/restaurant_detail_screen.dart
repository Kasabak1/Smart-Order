// lib/screens/restaurant_detail_screen.dart
import 'package:flutter/material.dart';

import '../models/mock_data.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends State<RestaurantDetailScreen> {
  TableModel? selectedTable;
  String selectedTime = '19:00 - Hôm nay';
  int guestCount = 4;

  final List<String> timeSlots = [
    '18:00 - Hôm nay',
    '19:00 - Hôm nay',
    '20:00 - Hôm nay',
    '11:30 - Ngày mai',
    '19:00 - Ngày mai',
  ];

  Color _getTableColor(TableModel table) {
    if (selectedTable?.id == table.id)
      return const Color(0xFFFF5722); // Đang chọn: Cam
    switch (table.status) {
      case 'AVAILABLE':
        return Colors.green.shade600; // Bàn trống: Xanh lá
      case 'BOOKED':
        return Colors.amber.shade700; // Đã đặt trước: Vàng cam
      case 'OCCUPIED':
        return Colors.grey.shade400; // Có khách đang ngồi: Xám
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh bìa nhà hàng
                Image.network(
                  widget.restaurant.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thông tin cơ bản
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.restaurant.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.restaurant.rating.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.restaurant.address,
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Giờ mở cửa: ${widget.restaurant.openTime}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // Chọn khung giờ & Số người
                      const Text(
                        '1. Chọn khung giờ & Số lượng khách',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: timeSlots.map((time) {
                          final isSelected = selectedTime == time;
                          return ChoiceChip(
                            label: Text(time),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFF5722)
                                .withOpacity(0.2),
                            onSelected: (_) =>
                                setState(() => selectedTime = time),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Số lượng khách: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            onPressed: guestCount > 1
                                ? () => setState(() => guestCount--)
                                : null,
                            icon: const Icon(
                              Icons.remove_circle_outline,
                            ),
                          ),
                          Text(
                            '$guestCount người',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => guestCount++),
                            icon: const Icon(
                              Icons.add_circle_outline,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // Sơ đồ bàn trực quan (UC04)
                      const Text(
                        '2. Sơ đồ bàn trực quan (Chọn bàn trống)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chú thích màu sắc bàn
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildLegend(
                            Colors.green.shade600,
                            'Trống',
                          ),
                          _buildLegend(
                            const Color(0xFFFF5722),
                            'Đang chọn',
                          ),
                          _buildLegend(
                            Colors.amber.shade700,
                            'Đã đặt trước',
                          ),
                          _buildLegend(
                            Colors.grey.shade400,
                            'Đang có khách',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Grid Sơ đồ bàn
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: mockTables.length,
                        itemBuilder: (context, index) {
                          final table = mockTables[index];
                          final isAvailable =
                              table.status == 'AVAILABLE';
                          return InkWell(
                            onTap: isAvailable
                                ? () => setState(
                                    () => selectedTable = table,
                                  )
                                : () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Bàn này đã có người đặt hoặc đang sử dụng!',
                                            ),
                                          ),
                                        );
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getTableColor(table)
                                    .withOpacity(0.15),
                                border: Border.all(
                                  color: _getTableColor(table),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(
                                  12,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    color: _getTableColor(table),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    table.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getTableColor(table),
                                    ),
                                  ),
                                  Text(
                                    '${table.seats} ghế',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Nút xác nhận Đặt giữ chỗ trước (UC05)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: selectedTable == null
                ? null
                : () {
                    setState(() {
                      selectedTable!.status = 'BOOKED';
                      myBookings.add(
                        BookingModel(
                          id: DateTime.now().millisecondsSinceEpoch
                              .toString(),
                          restaurant: widget.restaurant,
                          table: selectedTable!,
                          time: selectedTime,
                          guests: guestCount,
                        ),
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                          'Đặt thành công ${selectedTable!.name} lúc $selectedTime!',
                        ),
                      ),
                    );
                    Navigator.pop(context, true);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              selectedTable == null
                  ? 'VUI LÒNG CHỌN 1 BÀN TRỐNG'
                  : 'XÁC NHẬN ĐẶT ${selectedTable!.name.toUpperCase()} ($guestCount KHÁCH)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
