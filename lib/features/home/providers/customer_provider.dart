import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Model Nhà hàng
class Restaurant {
  final String id;
  final String name;
  final String address;
  final String openTime;
  final double rating;
  final String category;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.openTime,
    required this.rating,
    required this.category,
  });
}

// Danh sách nhà hàng mẫu
final restaurantListProvider = Provider<List<Restaurant>>((ref) {
  return [
    Restaurant(
      id: 'r1',
      name: 'Bếp Thái Koh Yam',
      address: '122 Thái Hà, Đống Đa, Hà Nội',
      openTime: '09:00 - 22:30',
      rating: 4.8,
      category: 'Lẩu & Món Thái',
    ),
    Restaurant(
      id: 'r2',
      name: 'Bò Tơ Quán Mộc',
      address: '102 Thái Thịnh, Đống Đa, Hà Nội',
      openTime: '10:00 - 23:00',
      rating: 4.6,
      category: 'Đặc sản đồng quê',
    ),
    Restaurant(
      id: 'r3',
      name: 'Pizza 4P\'s Tràng Tiền',
      address: '24 Tràng Tiền, Hoàn Kiếm, Hà Nội',
      openTime: '10:00 - 22:00',
      rating: 4.9,
      category: 'Món Âu / Pizza',
    ),
    Restaurant(
      id: 'r4',
      name: 'Lẩu Phan - Buffet Bò Úc',
      address: '7 Đào Duy Anh, Đống Đa, Hà Nội',
      openTime: '11:00 - 23:30',
      rating: 4.5,
      category: 'Buffet Lẩu',
    ),
  ];
});

// 2. Model Đơn Đặt Bàn
class Reservation {
  final String id;
  final String restaurantName;
  final String address;
  final String date;
  final String time;
  final int guests;
  final String note;
  final String status; // 'CONFIRMED' (Đã đặt) hoặc 'CANCELLED' (Đã hủy)

  Reservation({
    required this.id,
    required this.restaurantName,
    required this.address,
    required this.date,
    required this.time,
    required this.guests,
    this.note = '',
    this.status = 'CONFIRMED',
  });

  Reservation copyWith({String? status}) {
    return Reservation(
      id: id,
      restaurantName: restaurantName,
      address: address,
      date: date,
      time: time,
      guests: guests,
      note: note,
      status: status ?? this.status,
    );
  }
}

// Quản lý danh sách đặt bàn (Thêm mới, Hủy bàn)
class ReservationNotifier extends StateNotifier<List<Reservation>> {
  ReservationNotifier()
      : super([
          // Dữ liệu mẫu có sẵn để dễ test
          Reservation(
            id: '1001',
            restaurantName: 'Bếp Thái Koh Yam',
            address: '122 Thái Hà, Đống Đa, Hà Nội',
            date: '15/10/2026',
            time: '19:00',
            guests: 4,
            note: 'Ngồi gần cửa sổ',
            status: 'CONFIRMED',
          ),
          Reservation(
            id: '1000',
            restaurantName: 'Lẩu Phan - Buffet Bò Úc',
            address: '7 Đào Duy Anh, Đống Đa, Hà Nội',
            date: '02/10/2026',
            time: '18:30',
            guests: 2,
            note: 'Bận việc đột xuất',
            status: 'CANCELLED',
          ),
        ]);

  // Hàm Đặt bàn mới
  void addReservation(String restaurantName, String address, String date, String time, int guests, String note) {
    final newRes = Reservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      restaurantName: restaurantName,
      address: address,
      date: date,
      time: time,
      guests: guests,
      note: note,
      status: 'CONFIRMED',
    );
    state = [newRes, ...state]; // Đẩy đơn mới lên đầu danh sách
  }

  // Hàm Hủy đặt bàn
  void cancelReservation(String id) {
    state = [
      for (final res in state)
        if (res.id == id) res.copyWith(status: 'CANCELLED') else res
    ];
  }
}

final reservationProvider = StateNotifierProvider<ReservationNotifier, List<Reservation>>((ref) {
  return ReservationNotifier();
});

// 3. Model & Quản lý Thông tin cá nhân Khách hàng
class UserProfile {
  final String name;
  final String phone;
  final String email;
  final String address;

  UserProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
  });

  UserProfile copyWith({String? name, String? phone, String? email, String? address}) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier()
      : super(UserProfile(
          name: 'Nguyễn Văn Khách',
          phone: '0901111111',
          email: 'khachhang@gmail.com',
          address: 'Cầu Giấy, Hà Nội',
        ));

  void updateProfile({required String name, required String phone, required String email, required String address}) {
    state = state.copyWith(name: name, phone: phone, email: email, address: address);
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});