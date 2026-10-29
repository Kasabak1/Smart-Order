import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:str/main.dart';

SupabaseClient get _supabase => Supabase.instance.client;

// ============================================================================
// 1. MODEL & SUPABASE SERVICE CHO TÀI KHOẢN (BẢNG: accounts)
// ============================================================================
class AccountUser {
  final String id;
  final String name;
  final String phone;
  final String password;
  final String role; // 'CUSTOMER', 'ADMIN', 'STAFF', 'SUPER_ADMIN'
  final String subRole; // 'Phục vụ bàn', 'Bếp trưởng', 'Thu ngân'
  final String restaurantName;

  AccountUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    this.subRole = '',
    this.restaurantName = '', 
  });

  factory AccountUser.fromSupabase(Map<String, dynamic> row) {
    return AccountUser(
      id: row['id'].toString(),
      name: row['name'] ?? '',
      phone: row['phone'] ?? '',
      password: row['password'] ?? '',
      role: row['role'] ?? 'CUSTOMER',
      subRole: row['sub_role'] ?? '',
      restaurantName: row['restaurant_name'] ?? '', 
    );
  }

  // Hàm hỗ trợ cập nhật giao diện ngay lập tức khi thay đổi thông tin
  AccountUser copyWith({
    String? name,
    String? phone,
    String? password,
    String? role,
    String? subRole,
    String? restaurantName,
  }) {
    return AccountUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      subRole: subRole ?? this.subRole,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }
}

class AccountsDatabaseNotifier extends StateNotifier<List<AccountUser>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  AccountsDatabaseNotifier() : super([]) {
    _initSupabaseConnection();
  }

  void _initSupabaseConnection() {
    if (!isSupabaseConfigured) return;

    _subscription = _supabase
        .from('accounts')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      state = data.map((row) => AccountUser.fromSupabase(row)).toList();
    }, onError: (err) {
      debugPrint('Lỗi stream bảng accounts: $err');
    });
  }

  AccountUser? login(String phone, String password) {
    for (final user in state) {
      if (user.phone == phone && user.password == password) {
        return user;
      }
    }
    return null;
  }

  bool phoneExists(String phone) {
    return state.any((u) => u.phone == phone);
  }

  // ĐÃ SỬA: Hàm đăng ký hỗ trợ đầy đủ cho cả Chủ quán và Nhân viên
  Future<void> registerUser({
    required String name, 
    required String phone, 
    required String password, 
    required String role, 
    String subRole = '', 
    String restaurantName = ''
  }) async {
    if (!isSupabaseConfigured) return;
    try {
      await _supabase.from('accounts').insert({
        'name': name, 
        'phone': phone, 
        'password': password, 
        'role': role, 
        'sub_role': subRole,
        'restaurant_name': restaurantName
      });
    } catch (e) {
      debugPrint('Lỗi đăng ký: $e');
    }
  }

  Future<void> deleteStaff(String id) async {
    if (!isSupabaseConfigured) return;

    try {
      await _supabase.from('accounts').delete().eq('id', id);
    } catch (e) {
      debugPrint('Lỗi xóa tài khoản trên Supabase: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final accountsDbProvider = StateNotifierProvider<AccountsDatabaseNotifier, List<AccountUser>>((ref) {
  return AccountsDatabaseNotifier();
});

final currentUserProvider = StateProvider<AccountUser?>((ref) => null);


// ============================================================================
// 2. MODEL & SUPABASE SERVICE CHO THỰC ĐƠN (BẢNG: menu_items)
// ============================================================================
class MenuItemModel {
  final String id, name, category, icon, description, restaurantName, imageUrl;
  final int price;
  final bool isAvailable;

  MenuItemModel({
    required this.id, required this.name, required this.price, required this.category,
    required this.icon, required this.description, this.isAvailable = true, 
    required this.restaurantName, this.imageUrl = '',
  });

  MenuItemModel copyWith({bool? isAvailable}) => MenuItemModel(
        id: id, name: name, price: price, category: category, icon: icon, description: description,
        isAvailable: isAvailable ?? this.isAvailable, restaurantName: restaurantName, imageUrl: imageUrl,
      );

  factory MenuItemModel.fromSupabase(Map<String, dynamic> row) => MenuItemModel(
        id: row['id'].toString(),
        name: row['name'] ?? '',
        price: (row['price'] as num?)?.toInt() ?? 0,
        category: row['category'] ?? 'Món chính',
        icon: row['icon'] ?? '🍽️',
        description: row['description'] ?? '',
        isAvailable: row['is_available'] ?? true,
        restaurantName: row['restaurant_name'] ?? '',
        imageUrl: row['image_url'] ?? '', 
      );
}

class MenuDatabaseNotifier extends StateNotifier<List<MenuItemModel>> {
  StreamSubscription? _sub;
  MenuDatabaseNotifier() : super([]) {
    if (!isSupabaseConfigured) return;
    _sub = _supabase.from('menu_items').stream(primaryKey: ['id']).listen((data) {
      state = data.map((row) => MenuItemModel.fromSupabase(row)).toList();
    });
  }

  Future<void> addMenuItem({
    required String name, required int price, required String category, 
    required String description, required String restaurantName, XFile? imageFile,
  }) async {
    if (!isSupabaseConfigured) return;
    
    String finalImageUrl = '';

    try {
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final fileExt = imageFile.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await _supabase.storage.from('menu_images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );
        finalImageUrl = _supabase.storage.from('menu_images').getPublicUrl(fileName);
      }

      await _supabase.from('menu_items').insert({
        'name': name, 
        'price': price, 
        'category': category,
        'description': description, 
        'is_available': true, 
        'restaurant_name': restaurantName,
        'image_url': finalImageUrl, 
        'icon': '🍽️',
      });
    } catch (e) {
      debugPrint('Lỗi thêm món ăn: $e');
    }
  }

  Future<void> toggleAvailability(String id) async {
    if (!isSupabaseConfigured) return;
    final newStatus = !state.firstWhere((i) => i.id == id).isAvailable;
    await _supabase.from('menu_items').update({'is_available': newStatus}).eq('id', id);
  }

  Future<void> deleteMenuItem(String id) async {
    if (!isSupabaseConfigured) return;
    await _supabase.from('menu_items').delete().eq('id', id);
  }

  @override void dispose() { _sub?.cancel(); super.dispose(); }
}

final menuDbProvider = StateNotifierProvider<MenuDatabaseNotifier, List<MenuItemModel>>((ref) => MenuDatabaseNotifier());


// ============================================================================
// 3. ĐÁNH GIÁ NHÀ HÀNG (BẢNG: reviews)
// ============================================================================
class ReviewModel {
  final String id, restaurantName, userName, comment;
  final int rating;
  final DateTime createdAt;

  ReviewModel({required this.id, required this.restaurantName, required this.userName, required this.rating, required this.comment, required this.createdAt});

  factory ReviewModel.fromSupabase(Map<String, dynamic> row) {
    return ReviewModel(
      id: row['id'].toString(),
      restaurantName: row['restaurant_name'] ?? '',
      userName: row['user_name'] ?? 'Khách',
      rating: (row['rating'] as num?)?.toInt() ?? 5,
      comment: row['comment'] ?? '',
      createdAt: DateTime.parse(row['created_at']),
    );
  }
}

class ReviewsNotifier extends StateNotifier<List<ReviewModel>> {
  StreamSubscription? _sub;

  ReviewsNotifier() : super([]) {
    if (!isSupabaseConfigured) return;
    _sub = _supabase
        .from('reviews')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
      state = data.map((row) => ReviewModel.fromSupabase(row)).toList();
    });
  }

  Future<bool> addReview(String restaurantName, String userName, int rating, String comment) async {
    if (!isSupabaseConfigured) return false;
    try {
      await _supabase.from('reviews').insert({
        'restaurant_name': restaurantName,
        'user_name': userName,
        'rating': rating,
        'comment': comment,
      });
      return true;
    } catch (e) {
      debugPrint('Lỗi thêm đánh giá DB: $e');
      return false;
    }
  }

  @override void dispose() { _sub?.cancel(); super.dispose(); }
}

final reviewsProvider = StateNotifierProvider<ReviewsNotifier, List<ReviewModel>>((ref) => ReviewsNotifier());


// ============================================================================
// 4. QUẢN LÝ HỒ SƠ NHÀ HÀNG VÀ XÉT DUYỆT (BẢNG: restaurants)
// ============================================================================
class RestaurantModel {
  final String id, ownerPhone, name, address, category, openTime, imageUrl, status;
  final double lat, lng, rating;

  RestaurantModel({required this.id, required this.ownerPhone, required this.name, required this.address, required this.category, required this.openTime, required this.imageUrl, required this.lat, required this.lng, required this.rating, required this.status});

  factory RestaurantModel.fromSupabase(Map<String, dynamic> row) {
    return RestaurantModel(
      id: row['id'].toString(),
      ownerPhone: row['owner_phone'] ?? '',
      name: row['name'] ?? '',
      address: row['address'] ?? '',
      category: row['category'] ?? 'Đang cập nhật',
      openTime: row['open_time'] ?? '08:00 - 22:00',
      imageUrl: row['image_url'] ?? '',
      lat: (row['lat'] as num?)?.toDouble() ?? 21.0285,
      lng: (row['lng'] as num?)?.toDouble() ?? 105.8048,
      rating: (row['rating'] as num?)?.toDouble() ?? 5.0,
      status: row['status'] ?? 'PENDING', // PENDING, APPROVED, REJECTED
    );
  }
}

class RestaurantListNotifier extends StateNotifier<List<RestaurantModel>> {
  StreamSubscription? _sub;
  
  RestaurantListNotifier() : super([]) {
    if (!isSupabaseConfigured) return;
    _sub = _supabase.from('restaurants').stream(primaryKey: ['id']).listen((data) {
      state = data.map((row) => RestaurantModel.fromSupabase(row)).toList();
    });
  }

  // Hàm cho Chủ quán gửi yêu cầu phê duyệt hồ sơ lần đầu hoặc cập nhật
  Future<bool> submitStoreProfile(String ownerPhone, String name, String address, String category, String openTime, double lat, double lng) async {
    try {
      final existing = await _supabase.from('restaurants').select().eq('owner_phone', ownerPhone);
      
      if (existing.isEmpty) {
        await _supabase.from('restaurants').insert({
          'owner_phone': ownerPhone, 'name': name, 'address': address, 'category': category, 'open_time': openTime, 'lat': lat, 'lng': lng, 'status': 'PENDING'
        });
      } else {
        await _supabase.from('restaurants').update({
          'name': name, 'address': address, 'category': category, 'open_time': openTime, 'lat': lat, 'lng': lng, 'status': 'PENDING'
        }).eq('owner_phone', ownerPhone);
      }
      
      // Đồng bộ tên nhà hàng sang bảng tài khoản (rất quan trọng)
      await _supabase.from('accounts').update({'restaurant_name': name}).eq('phone', ownerPhone);
      
      return true;
    } catch (e) {
      debugPrint('Lỗi Gửi duyệt quán: $e');
      return false;
    }
  }

  // Hàm cho Super Admin đổi trạng thái duyệt (APPROVED, REJECTED)
  Future<bool> changeRestaurantStatus(String id, String newStatus) async {
    if (!isSupabaseConfigured) return false;
    try {
      await _supabase.from('restaurants').update({'status': newStatus}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Lỗi đổi trạng thái quán: $e');
      return false;
    }
  }

  @override void dispose() { _sub?.cancel(); super.dispose(); }
}

// Provider này phục vụ danh sách cửa hàng cho Khách (Chỉ hiển thị quán APPROVED) và Super Admin
final realRestaurantListProvider = StateNotifierProvider<RestaurantListNotifier, List<RestaurantModel>>((ref) => RestaurantListNotifier());