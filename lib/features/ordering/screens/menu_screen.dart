import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';

// Đổi sang ConsumerWidget để dùng Riverpod
class MenuScreen extends ConsumerWidget {
  final String tableId;
  MenuScreen({super.key, required this.tableId});

  // Dữ liệu món ăn giả lập (Mock data)
  final List<Map<String, dynamic>> dummyMenu = [
    {'name': 'Phở Bò Kobe', 'price': 99000, 'icon': '🍜', 'desc': 'Nước dùng thanh ngọt, thịt bò mềm.'},
    {'name': 'Gà Rán Sốt Cay', 'price': 55000, 'icon': '🍗', 'desc': 'Gà chiên giòn rụm, sốt cay Hàn Quốc.'},
    {'name': 'Trà Đào Cam Sả', 'price': 35000, 'icon': '🍹', 'desc': 'Giải khát thanh mát, ít đường.'},
    {'name': 'Bánh Mì Chảo', 'price': 45000, 'icon': '🥖', 'desc': 'Kèm pate, trứng ốp la, xúc xích.'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe sự thay đổi của giỏ hàng
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bàn: $tableId'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100), // Chừa chỗ cho thanh Giỏ hàng
        itemCount: dummyMenu.length,
        itemBuilder: (context, index) {
          final item = dummyMenu[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Text(item['icon'], style: const TextStyle(fontSize: 40)),
              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['desc'], maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${item['price']} đ', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: () {
                  // Thêm món vào giỏ
                  cartNotifier.addItem(item['name'], item['price']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm ${item['name']} vào giỏ!'),
                      duration: const Duration(milliseconds: 800),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          );
        },
      ),
      // Thanh thanh toán nổi ở dưới cùng (nếu có món trong giỏ mới hiện)
      bottomSheet: cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${cartNotifier.totalItems} món', style: const TextStyle(fontSize: 16)),
                        Text(
                          'Tổng: ${cartNotifier.totalPrice} đ',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      onPressed: () {
                        // Gọi API chốt đơn tại đây
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Thành công'),
                            content: const Text('Đơn hàng của bạn đã được gửi xuống bếp!'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              )
                            ],
                          ),
                        );
                      },
                      child: const Text('GỬI ĐƠN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}