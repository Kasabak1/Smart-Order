import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String name;
  final int price;
  int quantity;

  CartItem({required this.name, required this.price, this.quantity = 1});
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(String name, int price) {
    final existingIndex = state.indexWhere((item) => item.name == name);
    if (existingIndex >= 0) {
      state[existingIndex].quantity++;
      state = [...state];
    } else {
      state = [...state, CartItem(name: name, price: price)];
    }
  }

  // Hàm dùng để xóa sạch giỏ hàng sau khi gửi đơn thành công
  void clearCart() {
    state = [];
  }

  int get totalPrice => state.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});