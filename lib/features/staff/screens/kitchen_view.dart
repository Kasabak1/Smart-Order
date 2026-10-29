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
              labelColor: const Color(0xFFD84315),
              unselectedLabelColor: const Color(0xFF9A9FA5),
              indicatorColor: const Color(0xFFD84315),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              tabs: [
                Tab(icon: const Icon(Icons.local_fire_department_rounded), text: 'Đang chế biến (${activeOrders.length})'),
                Tab(icon: const Icon(Icons.task_alt_rounded), text: 'Đã hoàn thành (${completedOrders.length})'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF4F5F7),
              child: TabBarView(
                children: [
                  _buildKitchenOrderList(context, ref, activeOrders, isHistory: false),
                  _buildKitchenOrderList(context, ref, completedOrders, isHistory: true),
                ],
              ),
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
            Icon(Icons.soup_kitchen_outlined, size: 80, color: Colors.grey[350]),
            const SizedBox(height: 12),
            Text(
              isHistory ? 'Chưa có phiếu hoàn thành nào' : 'Bếp đang trống đơn! Tất cả món đã nấu xong.',
              style: const TextStyle(color: Color(0xFF9A9FA5), fontSize: 16, fontWeight: FontWeight.w600),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: [
              // Ticket Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isHistory
                        ? [const Color(0xFF546E7A), const Color(0xFF37474F)]
                        : [const Color(0xFFFF7043), const Color(0xFFD84315)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            order.tableNumber,
                            style: const TextStyle(color: Color(0xFFD84315), fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '#${order.orderId}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(order.createdAt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),

              // Ticket Items
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    ...order.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCCBC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'x${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFBF360C)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.dishName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                    if (item.note.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '⚠️ ${item.note}',
                                          style: const TextStyle(color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (item.status == DishStatus.pending)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFB8C00),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.outdoor_grill_rounded, size: 18),
                                  label: const Text('Nhận nấu', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    ref.read(kitchenOrdersProvider.notifier).updateDishStatus(order.orderId, item.id, DishStatus.cooking);
                                  },
                                )
                              else if (item.status == DishStatus.cooking)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C853),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.notifications_active_rounded, size: 18),
                                  label: const Text('Báo xong', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    ref.read(kitchenOrdersProvider.notifier).updateDishStatus(order.orderId, item.id, DishStatus.ready);
                                  },
                                )
                              else
                                const Chip(
                                  label: Text('Đã xong', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        )),
                    if (!isHistory)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.done_all_rounded, color: Color(0xFF00C853)),
                          label: const Text(
                            'Hoàn thành toàn bộ phiếu',
                            style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => ref.read(kitchenOrdersProvider.notifier).markAllReadyInOrder(order.orderId),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}