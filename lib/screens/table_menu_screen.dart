// lib/screens/table_menu_screen.dart
import 'package:flutter/material.dart';

import '../models/mock_data.dart';
import 'order_tracking_screen.dart';

class TableMenuScreen extends StatefulWidget {
  final String restaurantName;
  final String tableName;

  const TableMenuScreen({
    super.key,
    required this.restaurantName,
    required this.tableName,
  });

  @override
  State<TableMenuScreen> createState() => _TableMenuScreenState();
}

class _TableMenuScreenState extends State<TableMenuScreen> {
  String selectedCategory = 'Tất cả';
  final List<String> categories = [
    'Tất cả',
    'Khai vị',
    'Món chính',
    'Đồ uống',
    'Tráng miệng',
  ];

  int get totalCartItems =>
      sharedCart.fold(0, (sum, item) => sum + item.quantity);
  double get totalCartPrice => sharedCart.fold(
    0,
    (sum, item) => sum + (item.dish.price * item.quantity),
  );

  void _goToOrderTracking() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(
          restaurantName: widget.restaurantName,
          tableName: widget.tableName,
        ),
      ),
    );
    setState(() {}); // Làm mới lại giao diện khi quay lại
  }

  // Mở popup tùy chỉnh món ăn (UC09)
  void _showCustomizeDishSheet(Dish dish) {
    int quantity = 1;
    final TextEditingController noteController =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            dish.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                dish.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(dish.price),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFFF5722),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dish.description,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú cho Bếp (VD: Ít cay, không hành...)',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số lượng:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: quantity > 1
                                  ? () => setModalState(
                                      () => quantity--,
                                    )
                                  : null,
                              icon: const Icon(
                                Icons.remove_circle_outline,
                              ),
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setModalState(() => quantity++),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            final existingIndex = sharedCart
                                .indexWhere(
                                  (item) =>
                                      item.dish.id == dish.id &&
                                      item.note ==
                                          noteController.text.trim(),
                                );
                            if (existingIndex >= 0) {
                              sharedCart[existingIndex].quantity +=
                                  quantity;
                            } else {
                              sharedCart.add(
                                CartItem(
                                  dish: dish,
                                  quantity: quantity,
                                  note: noteController.text.trim(),
                                  addedBy: 'Bạn',
                                ),
                              );
                            }
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã thêm $quantity x ${dish.name} vào Giỏ hàng chung!',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
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
                        child: Text(
                          'THÊM VÀO GIỎ HÀNG CHUNG - ${formatCurrency(dish.price * quantity)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Mở Giỏ hàng chung & Xác nhận gửi đơn (UC10, UC11)
  void _showSharedCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Giỏ hàng chung của bàn (UC10)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${widget.tableName} • Mọi người cùng bàn có thể thêm món',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (sharedCart.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() => sharedCart.clear());
                                setModalState(() {});
                              },
                              child: const Text(
                                'Xóa tất cả',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: sharedCart.isEmpty
                            ? const Center(
                                child: Text(
                                  'Giỏ hàng đang trống. Hãy chọn món nhé!',
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: sharedCart.length,
                                itemBuilder: (context, index) {
                                  final item = sharedCart[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: Image.network(
                                        item.dish.imageUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    title: Text(
                                      item.dish.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${formatCurrency(item.dish.price)} • Thêm bởi: ${item.addedBy}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (item.note.isNotEmpty)
                                          Text(
                                            'Ghi chú: "${item.note}"',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontStyle:
                                                  FontStyle.italic,
                                              color:
                                                  Colors.deepOrange,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons
                                                .remove_circle_outline,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (item.quantity > 1) {
                                                item.quantity--;
                                              } else {
                                                sharedCart.removeAt(
                                                  index,
                                                );
                                              }
                                            });
                                            setModalState(() {});
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 22,
                                            color: Color(0xFFFF5722),
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => item.quantity++,
                                            );
                                            setModalState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tạm tính:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            formatCurrency(totalCartPrice),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nút Xác nhận gửi đơn (UC11) -> Chuyển thẳng sang màn hình Theo dõi tiến độ
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: sharedCart.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    for (var cartItem in sharedCart) {
                                      activeOrders.add(
                                        OrderItem(
                                          id: DateTime.now()
                                              .microsecondsSinceEpoch
                                              .toString(),
                                          dish: cartItem.dish,
                                          quantity: cartItem.quantity,
                                          note: cartItem.note,
                                          status: 'PENDING',
                                        ),
                                      );
                                    }
                                    sharedCart.clear();
                                  });
                                  Navigator.pop(
                                    context,
                                  ); // Đóng giỏ hàng
                                  _goToOrderTracking(); // Chuyển sang màn hình Theo dõi trạng thái món
                                },
                          icon: const Icon(Icons.send_rounded),
                          label: const Text(
                            'XÁC NHẬN GỬI ĐƠN XUỐNG BẾP (UC11)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMenu = selectedCategory == 'Tất cả'
        ? mockMenu
        : mockMenu
              .where((dish) => dish.category == selectedCategory)
              .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.restaurantName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.verified,
                  size: 14,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  'Đang ngồi tại: ${widget.tableName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Nút bấm xem Tiến độ đơn hàng & Thanh toán ngay trên góc phải AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: Colors.white,
              avatar: const Icon(
                Icons.receipt_long,
                size: 16,
                color: Color(0xFFFF5722),
              ),
              label: Text(
                'Đơn đã gọi (${activeOrders.length})',
                style: const TextStyle(
                  color: Color(0xFFFF5722),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: _goToOrderTracking,
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFF5722),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) =>
                            setState(() => selectedCategory = cat),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMenu.length,
                  itemBuilder: (context, index) {
                    final dish = filteredMenu[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: dish.isAvailable
                            ? () => _showCustomizeDishSheet(dish)
                            : () {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(
                                          'Món này hiện đã hết nguyên liệu! Vui lòng chọn món khác.',
                                        ),
                                      ),
                                    );
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: ColorFiltered(
                                      colorFilter: dish.isAvailable
                                          ? const ColorFilter.mode(
                                              Colors.transparent,
                                              BlendMode.multiply,
                                            )
                                          : const ColorFilter.mode(
                                              Colors.grey,
                                              BlendMode.saturation,
                                            ),
                                      child: Image.network(
                                        dish.imageUrl,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (!dish.isAvailable)
                                    Container(
                                      width: 90,
                                      height: 90,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'HẾT MÓN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dish.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: dish.isAvailable
                                            ? Colors.black87
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dish.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                      children: [
                                        Text(
                                          formatCurrency(dish.price),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: dish.isAvailable
                                                ? const Color(
                                                    0xFFFF5722,
                                                  )
                                                : Colors.grey,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: dish.isAvailable
                                              ? () =>
                                                    _showCustomizeDishSheet(
                                                      dish,
                                                    )
                                              : null,
                                          icon: const Icon(
                                            Icons.add,
                                            size: 16,
                                          ),
                                          label: const Text('Chọn'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(
                                                  0xFFFF5722,
                                                ),
                                            foregroundColor:
                                                Colors.white,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
              children: [
                InkWell(
                  onTap: _showSharedCartSheet,
                  child: Badge(
                    label: Text('$totalCartItems'),
                    isLabelVisible: totalCartItems > 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_basket_outlined,
                        color: Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: _showSharedCartSheet,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giỏ hàng chung của bàn',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          formatCurrency(totalCartPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _showSharedCartSheet,
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
                  child: const Text(
                    'Xem giỏ & Gửi đơn',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
