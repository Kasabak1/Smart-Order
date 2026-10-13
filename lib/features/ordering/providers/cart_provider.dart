import 'package:flutter_riverpod/flutter_riverpod.dart';

// Class đại diện cho 1 món trong giỏ
class CartItem {
  final String name;
  final int price;
  int quantity;

  CartItem({required this.name, required this.price, this.quantity = 1});
}

// StateNotifier quản lý danh sách món
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(String name, int price) {
    // Kiểm tra xem món đã có trong giỏ chưa
    final existingIndex = state.indexWhere((item) => item.name == name);
    if (existingIndex >= 0) {
      // Nếu có rồi thì tăng số lượng
      state[existingIndex].quantity++;
      state = [...state]; // Cập nhật lại UI
    } else {
      // Chưa có thì thêm mới
      state = [...state, CartItem(name: name, price: price)];
    }
  }

  int get totalPrice => state.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);
}

// Provider để các màn hình khác có thể gọi
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});