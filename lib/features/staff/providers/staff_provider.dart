import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:str/main.dart';

SupabaseClient get _supabase => Supabase.instance.client;

// ============================================================================
// 1. MODEL MÓN ĂN TRONG ĐƠN & ĐƠN HÀNG NHÀ BẾP (BẢNG: kitchen_orders)
// ============================================================================
enum DishStatus { pending, cooking, ready, served }

class OrderItem {
  final String id;
  final String dishName;
  final int quantity;
  final int price;
  final String note;
  final DishStatus status;

  OrderItem({
    required this.id,
    required this.dishName,
    required this.quantity,
    required this.price,
    this.note = '',
    this.status = DishStatus.pending,
  });

  OrderItem copyWith({DishStatus? status, int? quantity}) {
    return OrderItem(
      id: id,
      dishName: dishName,
      quantity: quantity ?? this.quantity,
      price: price,
      note: note,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dish_name': dishName,
      'quantity': quantity,
      'price': price,
      'note': note,
      'status': status.name,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status']?.toString() ?? 'pending';
    final parsedStatus = DishStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => DishStatus.pending,
    );

    return OrderItem(
      id: map['id']?.toString() ?? '',
      dishName: map['dish_name']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toInt() ?? 0,
      note: map['note']?.toString() ?? '',
      status: parsedStatus,
    );
  }
}

class KitchenOrder {
  final String orderId;
  final String tableNumber;
  final String createdAt;
  final List<OrderItem> items;

  KitchenOrder({
    required this.orderId,
    required this.tableNumber,
    required this.createdAt,
    required this.items,
  });

  KitchenOrder copyWith({List<OrderItem>? items}) {
    return KitchenOrder(
      orderId: orderId,
      tableNumber: tableNumber,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'order_id': orderId,
      'table_number': tableNumber,
      'created_at': createdAt,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  factory KitchenOrder.fromSupabaseMap(Map<String, dynamic> row) {
    final rawItems = row['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    return KitchenOrder(
      orderId: row['order_id']?.toString() ?? '',
      tableNumber: row['table_number']?.toString() ?? 'Bàn 01',
      createdAt: row['created_at']?.toString() ?? '',
      items: parsedItems,
    );
  }
}

class KitchenOrderNotifier extends StateNotifier<List<KitchenOrder>> {
  StreamSubscription<List<Map<String, dynamic>>>? _orderSubscription;

  KitchenOrderNotifier() : super(_initialMockOrders) {
    listenToRealtimeOrders();
  }

  static final List<KitchenOrder> _initialMockOrders = [
    KitchenOrder(
      orderId: 'ORD-101',
      tableNumber: 'Bàn 02',
      createdAt: '10:15',
      items: [
        OrderItem(
          id: 'i1',
          dishName: 'Phở Bò Kobe',
          quantity: 2,
          price: 99000,
          note: '1 bát không hành',
          status: DishStatus.pending,
        ),
        OrderItem(
          id: 'i2',
          dishName: 'Trà Đào Cam Sả',
          quantity: 2,
          price: 35000,
          status: DishStatus.cooking,
        ),
      ],
    ),
    KitchenOrder(
      orderId: 'ORD-102',
      tableNumber: 'Bàn 05',
      createdAt: '10:18',
      items: [
        OrderItem(
          id: 'i3',
          dishName: 'Gà Rán Sốt Cay',
          quantity: 1,
          price: 55000,
          note: 'Để sốt riêng',
          status: DishStatus.ready,
        ),
        OrderItem(
          id: 'i4',
          dishName: 'Bánh Mì Chảo',
          quantity: 2,
          price: 45000,
          status: DishStatus.pending,
        ),
      ],
    ),
  ];

  void listenToRealtimeOrders() {
    if (!isSupabaseConfigured) return;

    _orderSubscription = _supabase
        .from('kitchen_orders')
        .stream(primaryKey: ['order_id'])
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        state = data.map((row) => KitchenOrder.fromSupabaseMap(row)).toList();
      }
    }, onError: (err) {
      debugPrint('Lỗi Realtime kitchen_orders: $err');
    });
  }

  Future<void> updateDishStatus(String orderId, String itemId, DishStatus newStatus) async {
    List<OrderItem>? updatedItemsForCloud;

    state = [
      for (final order in state)
        if (order.orderId == orderId)
          () {
            final newItems = [
              for (final item in order.items)
                if (item.id == itemId) item.copyWith(status: newStatus) else item
            ];
            updatedItemsForCloud = newItems;
            return order.copyWith(items: newItems);
          }()
        else
          order
    ];

    if (!isSupabaseConfigured || updatedItemsForCloud == null) return;

    try {
      await _supabase.from('kitchen_orders').update({
        'items': updatedItemsForCloud!.map((e) => e.toMap()).toList(),
      }).eq('order_id', orderId);
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái món lên Supabase: $e');
    }
  }

  Future<void> markAllReadyInOrder(String orderId) async {
    List<OrderItem>? updatedItemsForCloud;

    state = [
      for (final order in state)
        if (order.orderId == orderId)
          () {
            final newItems = [
              for (final item in order.items)
                if (item.status == DishStatus.pending || item.status == DishStatus.cooking)
                  item.copyWith(status: DishStatus.ready)
                else
                  item
            ];
            updatedItemsForCloud = newItems;
            return order.copyWith(items: newItems);
          }()
        else
          order
    ];

    if (!isSupabaseConfigured || updatedItemsForCloud == null) return;

    try {
      await _supabase.from('kitchen_orders').update({
        'items': updatedItemsForCloud!.map((e) => e.toMap()).toList(),
      }).eq('order_id', orderId);
    } catch (e) {
      debugPrint('Lỗi markAllReadyInOrder trên Supabase: $e');
    }
  }

  Future<void> addOrderFromWaiter(String tableNumber, List<OrderItem> newItems) async {
    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final newOrder = KitchenOrder(
      orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      tableNumber: tableNumber,
      createdAt: timeStr,
      items: newItems,
    );

    state = [newOrder, ...state];

    if (!isSupabaseConfigured) return;

    try {
      await _supabase.from('kitchen_orders').insert(newOrder.toSupabaseMap());
    } catch (e) {
      debugPrint('Lỗi gửi đơn mới lên Supabase: $e');
    }
  }

  Future<void> clearOrdersForTable(String tableNumber) async {
    state = state.where((o) => o.tableNumber != tableNumber).toList();
    if (!isSupabaseConfigured) return;

    try {
      await _supabase.from('kitchen_orders').delete().eq('table_number', tableNumber);
    } catch (e) {
      debugPrint('Lỗi xóa đơn khi dọn bàn trên Supabase: $e');
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}

final kitchenOrdersProvider = StateNotifierProvider<KitchenOrderNotifier, List<KitchenOrder>>((ref) {
  return KitchenOrderNotifier();
});

// ============================================================================
// 2. MODEL & NOTIFIER ĐỒNG BỘ SƠ ĐỒ BÀN ĂN (Bổ sung trạng thái `reserved`)
// ============================================================================
enum TableState { empty, reserved, occupied, needPayment }

class RestaurantTable {
  final String number;
  final int seats;
  final TableState state;

  RestaurantTable({
    required this.number,
    required this.seats,
    required this.state,
  });

  RestaurantTable copyWith({TableState? state}) {
    return RestaurantTable(
      number: number,
      seats: seats,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'table_number': number,
      'seats': seats,
      'state': state.name,
    };
  }

  factory RestaurantTable.fromSupabaseMap(Map<String, dynamic> row) {
    final stateStr = row['state']?.toString() ?? 'empty';
    final parsedState = TableState.values.firstWhere(
      (e) => e.name == stateStr,
      orElse: () => TableState.empty,
    );

    return RestaurantTable(
      number: row['table_number']?.toString() ?? 'Bàn 01',
      seats: (row['seats'] as num?)?.toInt() ?? 4,
      state: parsedState,
    );
  }
}

class TableListNotifier extends StateNotifier<List<RestaurantTable>> {
  StreamSubscription<List<Map<String, dynamic>>>? _tableSubscription;

  TableListNotifier() : super(_generateDefaultTables()) {
    _initRealtimeTables();
  }

  static List<RestaurantTable> _generateDefaultTables() {
    return List.generate(12, (index) {
      final num = (index + 1).toString().padLeft(2, '0');
      final tableName = 'Bàn $num';
      TableState initialState = TableState.empty;
      if (tableName == 'Bàn 02' || tableName == 'Bàn 05') {
        initialState = TableState.occupied;
      } else if (tableName == 'Bàn 03') {
        initialState = TableState.reserved;
      } else if (tableName == 'Bàn 08') {
        initialState = TableState.needPayment;
      }
      return RestaurantTable(
        number: tableName,
        seats: (index % 3 == 0) ? 6 : 4,
        state: initialState,
      );
    });
  }

  Future<void> _initRealtimeTables() async {
    if (!isSupabaseConfigured) return;

    try {
      final existing = await _supabase.from('restaurant_tables').select();
      if (existing.isEmpty) {
        final seedData = _generateDefaultTables().map((t) => t.toSupabaseMap()).toList();
        await _supabase.from('restaurant_tables').insert(seedData);
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra dữ liệu bàn trên Supabase: $e');
    }

    _tableSubscription = _supabase
        .from('restaurant_tables')
        .stream(primaryKey: ['table_number'])
        .order('table_number', ascending: true)
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        state = data.map((row) => RestaurantTable.fromSupabaseMap(row)).toList();
      }
    }, onError: (err) {
      debugPrint('Lỗi Realtime restaurant_tables: $err');
    });
  }

  Future<void> setTableState(String tableNumber, TableState newState) async {
    state = [
      for (final t in state)
        if (t.number == tableNumber) t.copyWith(state: newState) else t
    ];

    if (!isSupabaseConfigured) return;

    try {
      await _supabase
          .from('restaurant_tables')
          .update({'state': newState.name})
          .eq('table_number', tableNumber);
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái bàn trên Supabase: $e');
    }
  }

  @override
  void dispose() {
    _tableSubscription?.cancel();
    super.dispose();
  }
}

final tableListProvider = StateNotifierProvider<TableListNotifier, List<RestaurantTable>>((ref) {
  return TableListNotifier();
});

// ============================================================================
// 3. MODEL & NOTIFIER ĐƠN ĐẶT BÀN (KHÁCH ĐẶT -> PHỤC VỤ DUYỆT & XẾP BÀN)
// ============================================================================
class Reservation {
  final String id;
  final String customerName;
  final String customerPhone;
  final String restaurantName;
  final String address;
  final String date;
  final String time;
  final int guests;
  final String note;
  final String status; // 'PENDING' (Chờ xếp bàn), 'CONFIRMED' (Đã xếp bàn), 'CANCELLED' (Đã hủy)
  final String? assignedTable; // VD: 'Bàn 03'

  Reservation({
    required this.id,
    this.customerName = 'Nguyễn Văn Khách',
    this.customerPhone = '0901111111',
    required this.restaurantName,
    required this.address,
    required this.date,
    required this.time,
    required this.guests,
    this.note = '',
    this.status = 'PENDING',
    this.assignedTable,
  });

  Reservation copyWith({String? status, String? assignedTable}) {
    return Reservation(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      restaurantName: restaurantName,
      address: address,
      date: date,
      time: time,
      guests: guests,
      note: note,
      status: status ?? this.status,
      assignedTable: assignedTable ?? this.assignedTable,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'restaurant_name': restaurantName,
      'address': address,
      'date': date,
      'time': time,
      'guests': guests,
      'note': note,
      'status': status,
      'assigned_table': assignedTable ?? '',
    };
  }

  factory Reservation.fromSupabaseMap(Map<String, dynamic> row) {
    final tableStr = row['assigned_table']?.toString() ?? '';
    return Reservation(
      id: row['id']?.toString() ?? '',
      customerName: row['customer_name']?.toString() ?? 'Khách hàng',
      customerPhone: row['customer_phone']?.toString() ?? '',
      restaurantName: row['restaurant_name']?.toString() ?? '',
      address: row['address']?.toString() ?? '',
      date: row['date']?.toString() ?? '',
      time: row['time']?.toString() ?? '',
      guests: (row['guests'] as num?)?.toInt() ?? 2,
      note: row['note']?.toString() ?? '',
      status: row['status']?.toString() ?? 'PENDING',
      assignedTable: tableStr.isEmpty ? null : tableStr,
    );
  }
}

class ReservationNotifier extends StateNotifier<List<Reservation>> {
  final Ref ref;
  StreamSubscription<List<Map<String, dynamic>>>? _resSubscription;

  ReservationNotifier(this.ref)
      : super([
          Reservation(
            id: 'RES-1002',
            customerName: 'Nguyễn Văn Khách',
            customerPhone: '0901111111',
            restaurantName: 'Bếp Thái Koh Yam',
            address: '122 Thái Hà, Đống Đa, Hà Nội',
            date: '15/10/2026',
            time: '19:00',
            guests: 4,
            note: 'Ngồi gần cửa sổ, có trẻ em',
            status: 'PENDING', // Đang chờ Phục vụ duyệt và xếp bàn
          ),
          Reservation(
            id: 'RES-1001',
            customerName: 'Trần Minh Anh',
            customerPhone: '0988777666',
            restaurantName: 'Bếp Thái Koh Yam',
            address: '122 Thái Hà, Đống Đa, Hà Nội',
            date: '15/10/2026',
            time: '18:30',
            guests: 6,
            note: 'Tiệc sinh nhật',
            status: 'CONFIRMED',
            assignedTable: 'Bàn 03',
          ),
        ]) {
    _initRealtimeReservations();
  }

  void _initRealtimeReservations() {
    if (!isSupabaseConfigured) return;

    _resSubscription = _supabase
        .from('reservations')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        state = data.map((r) => Reservation.fromSupabaseMap(r)).toList();
      }
    }, onError: (err) {
      debugPrint('Lỗi Realtime reservations: $err');
    });
  }

  // Khách hàng gửi yêu cầu Đặt bàn mới (Mặc định trạng thái PENDING chờ Phục vụ xếp bàn)
  Future<void> addReservation({
    required String customerName,
    required String customerPhone,
    required String restaurantName,
    required String address,
    required String date,
    required String time,
    required int guests,
    required String note,
  }) async {
    final newRes = Reservation(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      customerName: customerName,
      customerPhone: customerPhone,
      restaurantName: restaurantName,
      address: address,
      date: date,
      time: time,
      guests: guests,
      note: note,
      status: 'PENDING',
    );
    state = [newRes, ...state];

    if (!isSupabaseConfigured) return;
    try {
      await _supabase.from('reservations').insert(newRes.toSupabaseMap());
    } catch (e) {
      debugPrint('Lỗi thêm đặt bàn lên Supabase: $e');
    }
  }

  // Nhân viên Phục vụ nhận đơn và xếp bàn cho Khách hàng
  Future<void> assignTableToReservation(String reservationId, String tableNumber) async {
    state = [
      for (final res in state)
        if (res.id == reservationId)
          res.copyWith(status: 'CONFIRMED', assignedTable: tableNumber)
        else
          res
    ];

    // Tự động chuyển bàn đó trên Sơ đồ bàn sang trạng thái "Đã đặt trước" (reserved)
    ref.read(tableListProvider.notifier).setTableState(tableNumber, TableState.reserved);

    if (!isSupabaseConfigured) return;
    try {
      await _supabase.from('reservations').update({
        'status': 'CONFIRMED',
        'assigned_table': tableNumber,
      }).eq('id', reservationId);
    } catch (e) {
      debugPrint('Lỗi xếp bàn trên Supabase: $e');
    }
  }

  // Khách hàng hoặc Phục vụ hủy đặt bàn
  Future<void> cancelReservation(String id) async {
    String? tableToRelease;
    for (final res in state) {
      if (res.id == id && res.assignedTable != null) {
        tableToRelease = res.assignedTable;
      }
    }

    state = [
      for (final res in state)
        if (res.id == id) res.copyWith(status: 'CANCELLED') else res
    ];

    // Nếu đơn này đã được xếp bàn trước đó thì trả lại bàn trống
    if (tableToRelease != null) {
      ref.read(tableListProvider.notifier).setTableState(tableToRelease, TableState.empty);
    }

    if (!isSupabaseConfigured) return;
    try {
      await _supabase.from('reservations').update({'status': 'CANCELLED'}).eq('id', id);
    } catch (e) {
      debugPrint('Lỗi hủy đặt bàn trên Supabase: $e');
    }
  }

  @override
  void dispose() {
    _resSubscription?.cancel();
    super.dispose();
  }
}

final reservationProvider = StateNotifierProvider<ReservationNotifier, List<Reservation>>((ref) {
  return ReservationNotifier(ref);
});