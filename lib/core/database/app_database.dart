import 'dart:async';
import 'package:flutter/foundation.dart';
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
  final String role; // 'CUSTOMER', 'ADMIN', 'STAFF'
  final String subRole; // 'Phục vụ bàn', 'Bếp trưởng', 'Thu ngân'
  final String restaurantName;

  AccountUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    this.subRole = '',
    this.restaurantName = 'Bếp Thái Koh Yam',
  });

  // Chuyển đổi từ dòng dữ liệu PostgreSQL của Supabase sang Object Dart
  factory AccountUser.fromSupabase(Map<String, dynamic> row) {
    return AccountUser(
      id: row['id'].toString(),
      name: row['name'] ?? '',
      phone: row['phone'] ?? '',
      password: row['password'] ?? '',
      role: row['role'] ?? 'CUSTOMER',
      subRole: row['sub_role'] ?? '',
      restaurantName: row['restaurant_name'] ?? 'Bếp Thái Koh Yam',
    );
  }
}

class AccountsDatabaseNotifier extends StateNotifier<List<AccountUser>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  AccountsDatabaseNotifier() : super(_defaultUsers) {
    _initSupabaseConnection();
  }

  static final List<AccountUser> _defaultUsers = [
    AccountUser(
      id: 'u1',
      name: 'Nguyễn Văn Khách',
      phone: '0901111111',
      password: '123456',
      role: 'CUSTOMER',
    ),
    AccountUser(
      id: 'u2',
      name: 'Trần Chủ Quán',
      phone: '0902222222',
      password: '123456',
      role: 'ADMIN',
      restaurantName: 'Bếp Thái Koh Yam',
    ),
    AccountUser(
      id: 'u3',
      name: 'Lê Phục Vụ',
      phone: '0903333333',
      password: '123456',
      role: 'STAFF',
      subRole: 'Phục vụ bàn',
    ),
    AccountUser(
      id: 'u4',
      name: 'Phạm Bếp Trưởng',
      phone: '0904444444',
      password: '123456',
      role: 'STAFF',
      subRole: 'Bếp trưởng',
    ),
  ];

  void _initSupabaseConnection() {
    if (!isSupabaseConfigured) return;

    // Lắng nghe Realtime từ bảng `accounts` trên Supabase
    _subscription = _supabase
        .from('accounts')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        state = data.map((row) => AccountUser.fromSupabase(row)).toList();
      }
    }, onError: (err) {
      debugPrint('Lỗi stream bảng accounts: $err');
    });
  }

  // Hàm kiểm tra đăng nhập
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

  // Tạo tài khoản mới (Khách đăng ký hoặc Chủ quán cấp cho Nhân viên) -> Lưu lên Supabase
  Future<void> registerUser({
    required String name,
    required String phone,
    required String password,
    required String role,
    String subRole = '',
    String restaurantName = 'Bếp Thái Koh Yam',
  }) async {
    // Cập nhật giao diện ngay lập tức (Optimistic UI)
    final tempUser = AccountUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      password: password,
      role: role,
      subRole: subRole,
      restaurantName: restaurantName,
    );
    state = [...state, tempUser];

    if (!isSupabaseConfigured) return;

    try {
      await _supabase.from('accounts').insert({
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
        'sub_role': subRole,
        'restaurant_name': restaurantName,
      });
    } catch (e) {
      debugPrint('Lỗi thêm tài khoản lên Supabase: $e');
    }
  }

  // Xóa tài khoản nhân viên trên Supabase
  Future<void> deleteStaff(String id) async {
    state = state.where((u) => u.id != id).toList();
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
  final String id;
  final String name;
  final int price;
  final String category;
  final String icon;
  final String description;
  final bool isAvailable;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
    required this.description,
    this.isAvailable = true,
  });

  MenuItemModel copyWith({
    String? name,
    int? price,
    String? category,
    String? icon,
    String? description,
    bool? isAvailable,
  }) {
    return MenuItemModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory MenuItemModel.fromSupabase(Map<String, dynamic> row) {
    return MenuItemModel(
      id: row['id'].toString(),
      name: row['name'] ?? '',
      price: (row['price'] as num?)?.toInt() ?? 0,
      category: row['category'] ?? 'Món chính',
      icon: row['icon'] ?? '🍽️',
      description: row['description'] ?? '',
      isAvailable: row['is_available'] ?? true,
    );
  }
}

class MenuDatabaseNotifier extends StateNotifier<List<MenuItemModel>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  MenuDatabaseNotifier() : super(_defaultMenu) {
    _initSupabaseConnection();
  }

  static final List<MenuItemModel> _defaultMenu = [
    MenuItemModel(
      id: 'm1',
      name: 'Phở Bò Kobe',
      price: 99000,
      category: 'Món chính',
      icon: '🍜',
      description: 'Nước dùng thanh ngọt hầm xương 24h, thịt bò Kobe mềm tan.',
    ),
    MenuItemModel(
      id: 'm2',
      name: 'Gà Rán Sốt Cay',
      price: 55000,
      category: 'Món ăn nhẹ',
      icon: '🍗',
      description: 'Gà chiên giòn rụm phủ sốt cay Hàn Quốc.',
    ),
    MenuItemModel(
      id: 'm3',
      name: 'Trà Đào Cam Sả',
      price: 35000,
      category: 'Đồ uống',
      icon: '🍹',
      description: 'Giải khát thanh mát với đào miếng giòn và hương sả.',
    ),
    MenuItemModel(
      id: 'm4',
      name: 'Bánh Mì Chảo',
      price: 45000,
      category: 'Món chính',
      icon: '🥖',
      description: 'Kèm pate gan ngỗng, trứng ốp la, xúc xích và sốt tiêu đen.',
    ),
    MenuItemModel(
      id: 'm5',
      name: 'Lẩu Thái Tomyum',
      price: 250000,
      category: 'Lẩu',
      icon: '🍲',
      description: 'Nước lẩu chua cay chuẩn vị Thái, kèm hải sản và bò Mỹ.',
    ),
  ];

  void _initSupabaseConnection() {
    if (!isSupabaseConfigured) return;

    // Lắng nghe Realtime bảng `menu_items` từ Supabase
    _subscription = _supabase
        .from('menu_items')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        state = data.map((row) => MenuItemModel.fromSupabase(row)).toList();
      }
    }, onError: (err) {
      debugPrint('Lỗi stream bảng menu_items: $err');
    });
  }

  // Chủ quán thêm món mới lên Supabase
  Future<void> addMenuItem({
    required String name,
    required int price,
    required String category,
    required String icon,
    required String description,
  }) async {
    final cleanIcon = icon.isEmpty ? '🍽️' : icon;
    final tempItem = MenuItemModel(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      price: price,
      category: category,
      icon: cleanIcon,
      description: description,
    );
    state = [...state, tempItem];

    if (!isSupabaseConfigured) return;

    try {
      await _supabase.from('menu_items').insert({
        'name': name,
        'price': price,
        'category': category,
        'icon': cleanIcon,
        'description': description,
        'is_available': true,
      });
    } catch (e) {
      debugPrint('Lỗi thêm món ăn lên Supabase: $e');
    }
  }

  // Bật / Tắt trạng thái còn món trên Supabase
  Future<void> toggleAvailability(String id) async {
    final target = state.firstWhere((item) => item.id == id);
    final newStatus = !target.isAvailable;

    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isAvailable: newStatus) else item
    ];

    if (!isSupabaseConfigured) return;

    try {
      await _supabase
          .from('menu_items')
          .update({'is_available': newStatus})
          .eq('id', id);
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái món trên Supabase: $e');
    }
  }

  // Xóa món ăn trên Supabase
  Future<void> deleteMenuItem(String id) async {
    state = state.where((item) => item.id != id).toList();
    if (!isSupabaseConfigured) return;

    try {
      await _supabase.from('menu_items').delete().eq('id', id);
    } catch (e) {
      debugPrint('Lỗi xóa món trên Supabase: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final menuDbProvider = StateNotifierProvider<MenuDatabaseNotifier, List<MenuItemModel>>((ref) {
  return MenuDatabaseNotifier();
});