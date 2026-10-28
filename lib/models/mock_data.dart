class Dish {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imageUrl;
  final String description;
  bool
  isAvailable; // Kiểm tra tình trạng nguyên liệu (Còn món / Hết món)

  Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.description = 'Món ăn đặc trưng được chế biến từ nguyên liệu tươi ngon mỗi ngày.',
    this.isAvailable = true,
  });
}

class CartItem {
  final Dish dish;
  int quantity;
  String note; // Tùy chỉnh món: Ít cay, không hành...
  String addedBy; // Giỏ hàng chung: Ai là người thêm món này

  CartItem({
    required this.dish,
    this.quantity = 1,
    this.note = '',
    this.addedBy = 'Bạn',
  });
}

class OrderItem {
  final String id;
  final Dish dish;
  final int quantity;
  final String note;
  String status; // 'PENDING' (Chờ xác nhận), 'COOKING' (Đang nấu), 'READY' (Sẵn sàng), 'SERVED' (Đã phục vụ)

  OrderItem({
    required this.id,
    required this.dish,
    required this.quantity,
    this.note = '',
    this.status = 'PENDING',
  });
}

class Restaurant {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String imageUrl;
  final int availableTables;
  final String description;
  final String openTime;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.imageUrl,
    required this.availableTables,
    this.description = 'Không gian ấm cúng, hiện đại, phù hợp cho gia đình và tụ tập bạn bè.',
    this.openTime = '10:00 - 22:30',
  });
}

class TableModel {
  final String id;
  final String name;
  final int seats;
  String status; // 'AVAILABLE' (Trống), 'BOOKED' (Đã đặt), 'OCCUPIED' (Đang có khách)

  TableModel({
    required this.id,
    required this.name,
    required this.seats,
    required this.status,
  });
}

class BookingModel {
  final String id;
  final Restaurant restaurant;
  final TableModel table;
  final String time;
  final int guests;
  String status; // 'CONFIRMED' (Đã giữ chỗ), 'CANCELLED' (Đã hủy)

  BookingModel({
    required this.id,
    required this.restaurant,
    required this.table,
    required this.time,
    required this.guests,
    this.status = 'CONFIRMED',
  });
}

final List<Restaurant> mockRestaurants = [
  Restaurant(
    id: 'r1',
    name: 'Lẩu Phan - Buffet Bò Úc',
    address: 'Số 7 Đào Duy Anh, Đống Đa, Hà Nội',
    rating: 4.8,
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600',
    availableTables: 5,
  ),
  Restaurant(
    id: 'r2',
    name: 'Pizza 4P\'s - Tràng Tiền',
    address: '43 Tràng Tiền, Hoàn Kiếm, Hà Nội',
    rating: 4.9,
    imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
    availableTables: 2,
  ),
  Restaurant(
    id: 'r3',
    name: 'Gogi House - Nướng Hàn Quốc',
    address: 'Tầng 1 BigC Thăng Long, Cầu Giấy, Hà Nội',
    rating: 4.6,
    imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600',
    availableTables: 8,
  ),
];

final List<TableModel> mockTables = [
  TableModel(id: 't1', name: 'Bàn 01', seats: 2, status: 'AVAILABLE'),
  TableModel(id: 't2', name: 'Bàn 02', seats: 2, status: 'OCCUPIED'),
  TableModel(id: 't3', name: 'Bàn 03', seats: 4, status: 'AVAILABLE'),
  TableModel(id: 't4', name: 'Bàn 04', seats: 4, status: 'BOOKED'),
  TableModel(id: 't5', name: 'Bàn 05', seats: 4, status: 'AVAILABLE'),
  TableModel(id: 't6', name: 'Bàn 06', seats: 6, status: 'AVAILABLE'),
  TableModel(id: 't7', name: 'Bàn 07', seats: 6, status: 'OCCUPIED'),
  TableModel(
    id: 't8',
    name: 'Bàn 08 (VIP)',
    seats: 8,
    status: 'AVAILABLE',
  ),
  TableModel(
    id: 't9',
    name: 'Bàn 09 (VIP)',
    seats: 10,
    status: 'BOOKED',
  ),
];

List<BookingModel> myBookings = [];

final List<Dish> mockMenu = [
  Dish(
    id: 'd1',
    name: 'Ba chỉ bò Mỹ nướng sốt Galbi',
    price: 169000,
    category: 'Món chính',
    description: 'Thịt ba chỉ bò Mỹ thái lát vừa ăn, ướp sốt Galbi Hàn Quốc đậm đà.',
    imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500',
  ),
  Dish(
    id: 'd2',
    name: 'Pizza Burrata Phô mai tươi & Đùi heo muối',
    price: 298000,
    category: 'Món chính',
    description: 'Đế bánh nướng củi giòn rụm kết hợp phô mai Burrata béo ngậy.',
    imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500',
  ),
  Dish(
    id: 'd3',
    name: 'Salad rong biển trứng cua',
    price: 75000,
    category: 'Khai vị',
    description:
        'Rau xanh Đà Lạt trộn sốt mè rang kèm trứng cua giòn tan.',
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
  ),
  Dish(
    id: 'd4',
    name: 'Khoai tây chiên phủ phô mai tuyết',
    price: 59000,
    category: 'Khai vị',
    description:
        'Khoai tây chiên giòn lắc bột phô mai Hàn Quốc thơm lừng.',
    imageUrl: 'https://images.unsplash.com/photo-1576107232684-1279f3908594?w=500',
  ),
  Dish(
    id: 'd5',
    name: 'Sườn bò Hoàng Đế rút xương (Hết hàng)',
    price: 320000,
    category: 'Món chính',
    description:
        'Phần sườn bò cao cấp nhất, hiện đang tạm hết nguyên liệu.',
    imageUrl: 'https://images.unsplash.com/photo-1558030006-450675393462?w=500',
    isAvailable:
        false, // Giả lập món hết nguyên liệu theo Activity Diagram
  ),
  Dish(
    id: 'd6',
    name: 'Trà đào cam sả nhiệt đới',
    price: 45000,
    category: 'Đồ uống',
    description: 'Trà đen ủ lạnh kết hợp đào miếng giòn và hương sả thanh mát.',
    imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500',
  ),
  Dish(
    id: 'd7',
    name: 'Panna Cotta Chanh dây',
    price: 49000,
    category: 'Tráng miệng',
    description:
        'Bánh kem sữa Ý mềm mịn phủ sốt chanh dây chua ngọt.',
    imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=500',
  ),
];

// Giỏ hàng chung của bàn hiện tại (UC10)
List<CartItem> sharedCart = [
  CartItem(
    dish: mockMenu[2],
    quantity: 1,
    note: 'Ít sốt mè',
    addedBy: 'Bạn cùng bàn',
  ),
];

// Danh sách các món đã bấm "Xác nhận gửi đơn" xuống bếp (UC11)
List<OrderItem> activeOrders = [];

// Biến lưu thông tin bàn đang ngồi sau khi quét QR
String currentActiveTable = 'Bàn 03';
String currentActiveRestaurant = 'Lẩu Phan - Buffet Bò Úc';

// Hàm định dạng tiền tệ VNĐ (Ví dụ: 169.000đ)
String formatCurrency(double amount) {
  final str = amount.toInt().toString();
  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return '${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}đ';
}
