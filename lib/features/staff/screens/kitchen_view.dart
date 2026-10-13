import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str/features/staff/providers/staff_provider.dart';

class KitchenView extends ConsumerWidget {
  const KitchenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(kitchenOrdersProvider);

    final activeOrders = orders
        .where((o) => o.items.any((i) => i.status == DishStatus.pending || i.status == DishStatus.cooking))
        .toList();
    final completedOrders = orders
        .where((o) => o.items.every((i) => i.status == DishStatus.ready || i.status == DishStatus.served))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.deepOrange[800],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepOrange[800],
              tabs: [
                Tab(icon: const Icon(Icons.local_fire_department), text: 'Phiếu đang chế biến (${activeOrders.length})'),
                Tab(icon: const Icon(Icons.done_all), text: 'Phiếu đã hoàn thành (${completedOrders.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildKitchenOrderList(context, ref, activeOrders, isHistory: false),
                _buildKitchenOrderList(context, ref, completedOrders, isHistory: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenOrderList(BuildContext context, WidgetRef ref, List<KitchenOrder> orderList, {required bool isHistory}) {
    if (orderList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.soup_kitchen, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              isHistory ? 'Chưa có phiếu hoàn thành nào.' : 'Bếp đang rảnh! Không có món chờ nấu.',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orderList.length,
      itemBuilder: (context, index) {
        final order = orderList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isHistory ? Colors.grey[700] : Colors.deepOrange[700],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.table_bar, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${order.tableNumber}  •  #${order.orderId}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(order.createdAt, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...order.items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'x${item.quantity}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange[900]),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.dishName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (item.note.isNotEmpty)
                                    Text('⚠️ ${item.note}', style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  _buildDishStatusBadge(item.status),
                                ],
                              ),
                            ),
                            if (item.status == DishStatus.pending)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[800],
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.outdoor_grill, size: 18),
                                label: const Text('Nhận nấu'),
                                onPressed: () {
                                  ref.read(kitchenOrdersProvider.notifier).updateDishStatus(order.orderId, item.id, DishStatus.cooking);
                                },
                              )
                            else if (item.status == DishStatus.cooking)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.notifications_active, size: 18),
                                label: const Text('Báo xong'),
                                onPressed: () {
                                  ref.read(kitchenOrdersProvider.notifier).updateDishStatus(order.orderId, item.id, DishStatus.ready);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã báo Phục vụ bưng món: ${item.dishName} (${order.tableNumber})'),
                                      backgroundColor: Colors.green[800],
                                      duration: const Duration(milliseconds: 900),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    if (!isHistory) ...[
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.done_all, color: Colors.green),
                          label: const Text('Hoàn thành tất cả món trong phiếu này', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ref.read(kitchenOrdersProvider.notifier).markAllReadyInOrder(order.orderId);
                          },
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDishStatusBadge(DishStatus status) {
    switch (status) {
      case DishStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(6)),
          child: Text('Chờ bếp nhận', style: TextStyle(color: Colors.red[900], fontSize: 11, fontWeight: FontWeight.bold)),
        );
      case DishStatus.cooking:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(6)),
          child: Text('🔥 Đang chế biến', style: TextStyle(color: Colors.orange[900], fontSize: 11, fontWeight: FontWeight.bold)),
        );
      case DishStatus.ready:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(6)),
          child: Text('🔔 Chờ bưng ra bàn', style: TextStyle(color: Colors.green[900], fontSize: 11, fontWeight: FontWeight.bold)),
        );
      case DishStatus.served:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
          child: const Text('✓ Đã phục vụ', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        );
    }
  }
}