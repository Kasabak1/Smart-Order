import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:str/core/database/app_database.dart';
import 'package:str/features/ordering/providers/cart_provider.dart';
import 'package:str/features/staff/providers/staff_provider.dart';

class MenuScreen extends ConsumerWidget {
  final String restaurantName;
  final String tableId;

  const MenuScreen({
    super.key,
    required this.restaurantName,
    required this.tableId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(menuDbProvider)
        .where((m) => m.isAvailable && m.restaurantName == restaurantName)
        .toList();
        
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D26),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              restaurantName,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              'Đang phục vụ: $tableId',
              style: const TextStyle(fontSize: 12, color: Color(0xFFFF5722), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // BANNER HIỂN THỊ SỐ BÀN VỪA QUÉT ĐƯỢC
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.place_rounded, color: Color(0xFFFF5722), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Bạn đang ngồi tại: ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  tableId,
                  style: const TextStyle(color: Color(0xFFFF5722), fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

          // DANH SÁCH MÓN ĂN
          Expanded(
            child: menuItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('Nhà hàng hiện chưa cập nhật món!', style: TextStyle(color: Color(0xFF9A9FA5), fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 120),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final cartItemIndex = cartItems.indexWhere((c) => c.name == item.name);
                      final quantityInCart = cartItemIndex >= 0 ? cartItems[cartItemIndex].quantity : 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Container(
                                width: 85, 
                                height: 85,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5722).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  image: item.imageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(item.imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null, 
                                ),
                                child: item.imageUrl.isEmpty 
                                    ? Center(child: Text(item.icon, style: const TextStyle(fontSize: 45))) 
                                    : null, 
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1D26))),
                                    const SizedBox(height: 4),
                                    Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9A9FA5), fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Text('${item.price} đ', style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w900, fontSize: 16)),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: quantityInCart > 0 ? const Color(0xFFFF5722) : const Color(0xFFF4F6FA),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: IconButton(
                                  icon: Icon(quantityInCart > 0 ? Icons.add_shopping_cart_rounded : Icons.add_rounded, color: quantityInCart > 0 ? Colors.white : const Color(0xFFFF5722)),
                                  onPressed: () {
                                    cartNotifier.addItem(item.name, item.price);
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white), const SizedBox(width: 10), Text('Đã thêm ${item.name}')]),
                                        backgroundColor: const Color(0xFF00C853), duration: const Duration(milliseconds: 800), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
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

      // THANH GIỎ HÀNG NỔI
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: cartItems.isEmpty
          ? null
          : Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFF1A1D26), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF1A1D26).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22)), const SizedBox(width: 14),
                        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${cartNotifier.totalItems} món đã chọn', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)), Text('${cartNotifier.totalPrice} đ', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                      onPressed: () {
                        final orderItems = cartItems.map((c) => OrderItem(
                          id: '${DateTime.now().microsecondsSinceEpoch}_${c.name}', dishName: c.name, quantity: c.quantity, price: c.price, note: 'Khách tự đặt qua App', status: DishStatus.pending,
                        )).toList();

                        ref.read(kitchenOrdersProvider.notifier).addOrderFromWaiter(tableId, orderItems);
                        ref.read(tableListProvider.notifier).setTableState(tableId, TableState.occupied);
                        cartNotifier.clearCart();

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            title: const Column(children: [Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 70), SizedBox(height: 16), Text('Gửi đơn thành công!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1A1D26)))]),
                            content: Text('Đơn hàng của bạn tại $tableId đã được gửi xuống Nhà bếp.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5)),
                            actionsAlignment: MainAxisAlignment.center, actionsPadding: const EdgeInsets.only(bottom: 24),
                            actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14), elevation: 0), onPressed: () { Navigator.pop(context); context.pop(); }, child: const Text('Quay về Trang chủ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))],
                          ),
                        );
                      },
                      child: const Text('GỬI ĐƠN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}