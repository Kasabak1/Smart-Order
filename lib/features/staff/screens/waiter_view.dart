import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str/core/database/app_database.dart';
import 'package:str/features/staff/providers/staff_provider.dart';

class WaiterView extends ConsumerWidget {
  final int readyToServeCount;
  final int pendingBookingCount;

  const WaiterView({
    super.key,
    required this.readyToServeCount,
    required this.pendingBookingCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.green[800],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green[800],
              tabs: [
                const Tab(icon: Icon(Icons.grid_view), text: 'Sơ đồ bàn'),
                Tab(
                  icon: Badge(
                    isLabelVisible: pendingBookingCount > 0,
                    label: Text('$pendingBookingCount'),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.event_seat),
                  ),
                  text: 'Đặt bàn ($pendingBookingCount)',
                ),
                Tab(
                  icon: Badge(
                    isLabelVisible: readyToServeCount > 0,
                    label: Text('$readyToServeCount'),
                    child: const Icon(Icons.notifications_active),
                  ),
                  text: 'Chờ bưng ($readyToServeCount)',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTableMapTab(context, ref),
                _buildReservationManagementTab(context, ref),
                _buildReadyToServeTab(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: SƠ ĐỒ BÀN ĂN
  // ==========================================================================
  Widget _buildTableMapTab(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tableListProvider);
    final orders = ref.watch(kitchenOrdersProvider);
    final reservations = ref.watch(reservationProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(Colors.grey[300]!, 'Trống'),
              _buildLegendItem(Colors.purple[100]!, 'Đã xếp lịch đặt'),
              _buildLegendItem(Colors.green[200]!, 'Đang ăn'),
              _buildLegendItem(Colors.amber[200]!, 'Chờ tính tiền'),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              int readyCountForTable = 0;
              for (final o in orders.where((ord) => ord.tableNumber == table.number)) {
                readyCountForTable += o.items.where((i) => i.status == DishStatus.ready).length;
              }

              // Tìm xem bàn này đang được xếp cho khách đặt trước nào không
              final activeRes = reservations
                  .where((r) => r.status == 'CONFIRMED' && r.assignedTable == table.number)
                  .firstOrNull;

              Color cardColor = Colors.grey[200]!;
              Color iconColor = Colors.grey[700]!;
              String statusText = 'Trống (${table.seats} ghế)';

              if (table.state == TableState.reserved) {
                cardColor = Colors.purple[50]!;
                iconColor = Colors.purple[700]!;
                statusText = activeRes != null ? 'Đã đặt (${activeRes.time})' : 'Đã đặt trước';
              } else if (table.state == TableState.occupied) {
                cardColor = Colors.green[100]!;
                iconColor = Colors.green[800]!;
                statusText = 'Đang phục vụ';
              } else if (table.state == TableState.needPayment) {
                cardColor = Colors.amber[100]!;
                iconColor = Colors.orange[900]!;
                statusText = 'Gọi thanh toán';
              }

              return InkWell(
                onTap: () => _showTableActionSheet(context, ref, table, activeRes),
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Card(
                      color: cardColor,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: iconColor.withOpacity(0.4), width: 1.5),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.table_restaurant, color: iconColor, size: 34),
                              const SizedBox(height: 4),
                              Text(table.number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                statusText,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w600),
                              ),
                              if (activeRes != null && table.state == TableState.reserved)
                                Text(
                                  activeRes.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: Colors.purple[900]),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (readyCountForTable > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$readyCountForTable món xong',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ==========================================================================
  // TAB 2: PHỤC VỤ NHẬN ĐƠN ĐẶT BÀN & XẾP BÀN CHO KHÁCH
  // ==========================================================================
  Widget _buildReservationManagementTab(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(reservationProvider);
    final pendingList = reservations.where((r) => r.status == 'PENDING').toList();
    final confirmedList = reservations.where((r) => r.status == 'CONFIRMED').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.pending_actions, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text(
              'Yêu cầu chờ xếp bàn (${pendingList.length})',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (pendingList.isEmpty)
          Card(
            color: Colors.grey[100],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Hiện không có yêu cầu đặt bàn mới nào đang chờ duyệt.'),
            ),
          )
        else
          ...pendingList.map((res) => _buildReservationCard(context, ref, res, isPending: true)),

        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.event_available, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Đã xếp bàn thành công (${confirmedList.length})',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (confirmedList.isEmpty)
          Card(
            color: Colors.grey[100],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chưa có bàn nào được xếp lịch.'),
            ),
          )
        else
          ...confirmedList.map((res) => _buildReservationCard(context, ref, res, isPending: false)),
      ],
    );
  }

  Widget _buildReservationCard(BuildContext context, WidgetRef ref, Reservation res, {required bool isPending}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPending ? Colors.orange : Colors.green, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '👤 ${res.customerName} (${res.customerPhone})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange[100] : Colors.purple[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPending ? 'Chờ xếp bàn' : 'Đã xếp: ${res.assignedTable}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isPending ? Colors.deepOrange[900] : Colors.purple[900],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Ngày: ${res.date}'),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Giờ: ${res.time}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                const Icon(Icons.groups, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Text('${res.guests} khách', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            if (res.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('📝 Ghi chú: ${res.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Từ chối / Hủy'),
                  onPressed: () {
                    ref.read(reservationProvider.notifier).cancelReservation(res.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã hủy yêu cầu đặt bàn.'), backgroundColor: Colors.redAccent),
                    );
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending ? Colors.green[700] : Colors.purple[700],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.table_bar, size: 18),
                  label: Text(isPending ? 'Chọn bàn & Duyệt' : 'Đổi bàn khác'),
                  onPressed: () => _showAssignTableDialog(context, ref, res),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Hộp thoại để Nhân viên Phục vụ chọn bàn trống phù hợp với số khách
  void _showAssignTableDialog(BuildContext context, WidgetRef ref, Reservation res) {
    final allTables = ref.read(tableListProvider);
    // Lọc các bàn đang trống (hoặc chính bàn hiện tại của đơn đó)
    final availableTables = allTables
        .where((t) => t.state == TableState.empty || t.number == res.assignedTable)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Xếp bàn cho ${res.customerName} (${res.guests} khách)'),
          content: availableTables.isEmpty
              ? const Text('Hiện tại tất cả các bàn đều đang bận hoặc đã được đặt kín!')
              : SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn 1 bàn trống bên dưới để gán cho khách:', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: availableTables.map((table) {
                          final bool isEnoughSeats = table.seats >= res.guests;
                          return ActionChip(
                            avatar: Icon(
                              Icons.table_restaurant,
                              size: 18,
                              color: isEnoughSeats ? Colors.green[800] : Colors.orange[800],
                            ),
                            backgroundColor: isEnoughSeats ? Colors.green[50] : Colors.orange[50],
                            label: Text(
                              '${table.number} (${table.seats} ghế)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              // Nếu đổi từ bàn cũ sang bàn mới, giải phóng bàn cũ trước
                              if (res.assignedTable != null && res.assignedTable != table.number) {
                                ref.read(tableListProvider.notifier).setTableState(res.assignedTable!, TableState.empty);
                              }

                              ref.read(reservationProvider.notifier).assignTableToReservation(res.id, table.number);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã xếp ${table.number} cho khách ${res.customerName}!'),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // POPUP THAO TÁC KHI BẤM VÀO 1 BÀN TRÊN SƠ ĐỒ
  // ==========================================================================
  void _showTableActionSheet(BuildContext context, WidgetRef ref, RestaurantTable table, Reservation? activeRes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final allOrders = ref.watch(kitchenOrdersProvider);
            final tableOrders = allOrders.where((o) => o.tableNumber == table.number).toList();

            int totalBill = 0;
            for (final o in tableOrders) {
              for (final i in o.items) {
                totalBill += i.price * i.quantity;
              }
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${table.number} (${table.seats} ghế)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text(
                          table.state == TableState.empty
                              ? 'Bàn trống'
                              : table.state == TableState.reserved
                                  ? 'Đã đặt trước'
                                  : table.state == TableState.occupied
                                      ? 'Đang có khách'
                                      : 'Chờ thanh toán',
                        ),
                      ),
                    ],
                  ),
                  if (activeRes != null && table.state == TableState.reserved) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📌 Khách đặt trước: ${activeRes.customerName} (${activeRes.customerPhone})',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('⏰ Giờ hẹn: ${activeRes.time} - Ngày ${activeRes.date} (${activeRes.guests} người)'),
                          if (activeRes.note.isNotEmpty) Text('📝 Lưu ý: ${activeRes.note}'),
                        ],
                      ),
                    ),
                  ],
                  const Divider(),
                  if (tableOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Bàn này hiện chưa gọi món nào.', style: TextStyle(color: Colors.grey)),
                    )
                  else ...[
                    const Text('Các món đã gọi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final order in tableOrders)
                            for (final item in order.items)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text('${item.dishName} (x${item.quantity})', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${item.price * item.quantity} đ ${item.note.isNotEmpty ? "• ${item.note}" : ""}'),
                                trailing: _buildStatusChip(item.status),
                              ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('$totalBill đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Gọi thêm món hộ khách'),
                        onPressed: () {
                          Navigator.pop(context);
                          _showWaiterOrderDialog(context, ref, table.number);
                        },
                      ),
                      if (table.state == TableState.empty || table.state == TableState.reserved)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          icon: const Icon(Icons.people),
                          label: Text(table.state == TableState.reserved ? 'Khách đã đến (Nhận bàn)' : 'Mở bàn (Đón khách)'),
                          onPressed: () {
                            ref.read(tableListProvider.notifier).setTableState(table.number, TableState.occupied);
                            Navigator.pop(context);
                          },
                        ),
                      if (table.state == TableState.occupied)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.receipt_long, color: Colors.orange),
                          label: const Text('Khách gọi tính tiền'),
                          onPressed: () {
                            ref.read(tableListProvider.notifier).setTableState(table.number, TableState.needPayment);
                            Navigator.pop(context);
                          },
                        ),
                      if (table.state != TableState.empty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Thanh toán & Dọn bàn'),
                          onPressed: () {
                            ref.read(tableListProvider.notifier).setTableState(table.number, TableState.empty);
                            ref.read(kitchenOrdersProvider.notifier).clearOrdersForTable(table.number);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã thanh toán và dọn sạch ${table.number}!'), backgroundColor: Colors.green),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWaiterOrderDialog(BuildContext context, WidgetRef ref, String tableNumber) {
    final menuCatalog = ref
        .read(menuDbProvider)
        .where((m) => m.isAvailable)
        .map((m) => {'name': m.name, 'price': m.price})
        .toList();

    final Map<String, int> selectedQuantities = {};
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Gọi món - $tableNumber'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...menuCatalog.map((dish) {
                        final name = dish['name'] as String;
                        final price = dish['price'] as int;
                        final qty = selectedQuantities[name] ?? 0;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('$price đ'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: qty > 0
                                    ? () => setDialogState(() => selectedQuantities[name] = qty - 1)
                                    : null,
                              ),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () => setDialogState(() => selectedQuantities[name] = qty + 1),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú cho Bếp (VD: Ít cay, không hành...)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () {
                    final List<OrderItem> itemsToSend = [];
                    selectedQuantities.forEach((dishName, qty) {
                      if (qty > 0) {
                        final price = menuCatalog.firstWhere((m) => m['name'] == dishName)['price'] as int;
                        itemsToSend.add(
                          OrderItem(
                            id: '${DateTime.now().microsecondsSinceEpoch}_$dishName',
                            dishName: dishName,
                            quantity: qty,
                            price: price,
                            note: noteCtrl.text.trim(),
                            status: DishStatus.pending,
                          ),
                        );
                      }
                    });

                    if (itemsToSend.isNotEmpty) {
                      ref.read(kitchenOrdersProvider.notifier).addOrderFromWaiter(tableNumber, itemsToSend);
                      ref.read(tableListProvider.notifier).setTableState(tableNumber, TableState.occupied);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã gửi đơn của $tableNumber xuống Nhà Bếp!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: const Text('Gửi xuống Bếp'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // TAB 3: DANH SÁCH MÓN BẾP ĐÃ NẤU XONG CHỜ BƯNG RA BÀN
  // ==========================================================================
  Widget _buildReadyToServeTab(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(kitchenOrdersProvider);

    final List<Map<String, dynamic>> readyItems = [];
    for (final order in orders) {
      for (final item in order.items) {
        if (item.status == DishStatus.ready) {
          readyItems.add({
            'orderId': order.orderId,
            'tableNumber': order.tableNumber,
            'item': item,
          });
        }
      }
    }

    if (readyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('Tất cả món nấu xong đã được bưng ra bàn!', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: readyItems.length,
      itemBuilder: (context, index) {
        final data = readyItems[index];
        final String orderId = data['orderId'];
        final String tableNumber = data['tableNumber'];
        final OrderItem item = data['item'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.green[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.green, width: 1.5),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.room_service, color: Colors.white),
            ),
            title: Text('${item.dishName} (x${item.quantity})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            subtitle: Text('Giao tới: $tableNumber ${item.note.isNotEmpty ? "\nLưu ý: ${item.note}" : ""}'),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Đã bưng ra'),
              onPressed: () {
                ref.read(kitchenOrdersProvider.notifier).updateDishStatus(orderId, item.id, DishStatus.served);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã phục vụ ${item.dishName} cho $tableNumber!'),
                    duration: const Duration(milliseconds: 900),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(DishStatus status) {
    switch (status) {
      case DishStatus.pending:
        return const Text('Chờ bếp', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold));
      case DishStatus.cooking:
        return const Text('Đang nấu', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold));
      case DishStatus.ready:
        return const Text('Chờ bưng', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold));
      case DishStatus.served:
        return const Text('Đã lên món', style: TextStyle(color: Colors.grey, fontSize: 12));
    }
  }
}