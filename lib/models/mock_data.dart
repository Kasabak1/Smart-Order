class Dish {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imageUrl;
  final bool isAvailable;

  Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.isAvailable = true,
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

//so do 9 ban mau cho moi nha hang
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

//danh sach luu ls dat ban cua khach
List<BookingModel> myBookings = [];

final List<Dish> mockMenu = [
  Dish(
    id: 'd1',
    name: 'Ba chỉ bò Mỹ nướng sốt Galbi',
    price: 169000,
    category: 'Món chính',
    imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500',
  ),
  Dish(
    id: 'd2',
    name: 'Pizza Burrata Phô mai tươi & Đùi heo muối',
    price: 298000,
    category: 'Món chính',
    imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500',
  ),
  Dish(
    id: 'd3',
    name: 'Salad rong biển trứng cua',
    price: 75000,
    category: 'Khai vị',
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
  ),
  Dish(
    id: 'd4',
    name: 'Trà đào cam sả nhiệt đới',
    price: 45000,
    category: 'Đồ uống',
    imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500',
  ),
];
