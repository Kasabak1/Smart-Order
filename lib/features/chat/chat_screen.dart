import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:str/main.dart';
import 'package:str/core/database/app_database.dart';
import 'package:str/features/home/screens/main_dashboard_screen.dart';

SupabaseClient get _supabase => Supabase.instance.client;

// ============================================================================
// 1. MODEL & REALTIME PROVIDER CHO TIN NHẮN CHAT (Có thêm phân loại Nhà Hàng)
// ============================================================================
class ChatMessage {
  final String id, roomId, restaurantName, customerName, senderRole, senderName, content, createdAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.restaurantName,
    required this.customerName,
    required this.senderRole,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toSupabaseMap() => {
        'id': id,
        'room_id': roomId,
        'restaurant_name': restaurantName,
        'customer_name': customerName,
        'sender_role': senderRole,
        'sender_name': senderName,
        'content': content,
        'created_at': createdAt,
      };

  factory ChatMessage.fromSupabaseMap(Map<String, dynamic> row) => ChatMessage(
        id: row['id']?.toString() ?? '',
        roomId: row['room_id']?.toString() ?? '',
        restaurantName: row['restaurant_name']?.toString() ?? '',
        customerName: row['customer_name']?.toString() ?? 'Khách hàng',
        senderRole: row['sender_role']?.toString() ?? 'CUSTOMER',
        senderName: row['sender_name']?.toString() ?? '',
        content: row['content']?.toString() ?? '',
        createdAt: row['created_at']?.toString() ?? '',
      );
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  StreamSubscription<List<Map<String, dynamic>>>? _chatSub;

  ChatNotifier() : super([]) {
    _initRealtimeChat();
  }

  void _initRealtimeChat() {
    if (!isSupabaseConfigured) return;

    _chatSub = _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('id', ascending: true)
        .listen((data) {
      if (data.isNotEmpty) {
        state = data.map((r) => ChatMessage.fromSupabaseMap(r)).toList();
      }
    }, onError: (err) {
      debugPrint('Lỗi Realtime chat_messages: $err');
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String restaurantName,
    required String customerName,
    required String senderRole,
    required String senderName,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      restaurantName: restaurantName,
      customerName: customerName,
      senderRole: senderRole,
      senderName: senderName,
      content: text,
      createdAt: timeStr,
    );

    state = [...state, newMsg];

    if (!isSupabaseConfigured) return;
    try {
      await _supabase.from('chat_messages').insert(newMsg.toSupabaseMap());
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn lên Supabase: $e');
    }
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});

// ============================================================================
// 2. MÀN HÌNH PHÒNG CHAT CHI TIẾT
// ============================================================================
class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId, restaurantName, customerName, currentRole, currentSenderName, title;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.restaurantName,
    required this.customerName,
    required this.currentRole,
    required this.currentSenderName,
    required this.title,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  void _handleSend([String? quickText]) {
    final text = quickText ?? _msgController.text;
    if (text.trim().isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(
          roomId: widget.roomId,
          restaurantName: widget.restaurantName,
          customerName: widget.customerName,
          senderRole: widget.currentRole,
          senderName: widget.currentSenderName,
          content: text,
        );

    if (quickText == null) _msgController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allMessages = ref.watch(chatProvider);
    final roomMessages = allMessages.where((m) => m.roomId == widget.roomId).toList();

    final List<String> quickReplies = widget.currentRole == 'CUSTOMER'
        ? ['Quán còn bàn trống tối nay không ạ?', 'Cho mình xin ghế trẻ em nhé', 'Cho mình gọi thanh toán nhé!']
        : ['Dạ nhà hàng đã nhận yêu cầu ạ!', 'Dạ bàn của mình đã được giữ chỗ rồi ạ.', 'Món ăn đang được chuẩn bị nhé bạn.'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D26),
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFF5722).withOpacity(0.12),
              child: Icon(
                widget.currentRole == 'CUSTOMER' ? Icons.storefront_rounded : Icons.person_rounded,
                color: const Color(0xFFFF5722),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF00C853), size: 8),
                      SizedBox(width: 4),
                      Text('Đang trực tuyến', style: TextStyle(fontSize: 11, color: Color(0xFF6C7278))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: roomMessages.isEmpty
                ? const Center(child: Text('Hãy gửi tin nhắn đầu tiên!', style: TextStyle(color: Color(0xFF9A9FA5))))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: roomMessages.length,
                    itemBuilder: (context, index) {
                      final msg = roomMessages[index];
                      final isMe = msg.senderRole == widget.currentRole;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isMe ? const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFFF5722)]) : null,
                            color: isMe ? null : Colors.white,
                            borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(isMe ? 20 : 4), bottomRight: Radius.circular(isMe ? 4 : 20)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(msg.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)))),
                              Text(msg.content, style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1A1D26), fontSize: 14, height: 1.35)),
                              const SizedBox(height: 4),
                              Text(msg.createdAt, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : const Color(0xFF9A9FA5))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ActionChip(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: const Color(0xFFFF5722).withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  label: Text(quickReplies[index], style: const TextStyle(fontSize: 12, color: Color(0xFFFF5722), fontWeight: FontWeight.w600)),
                  onPressed: () => _handleSend(quickReplies[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -2))]),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(hintText: 'Nhập tin nhắn...', filled: true, fillColor: const Color(0xFFF4F6FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFFF5722)])),
                    child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: () => _handleSend()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. HỘP THƯ DÀNH CHO KHÁCH HÀNG (Hiển thị các Nhà hàng đã Chat)
// ============================================================================
class CustomerChatListView extends ConsumerWidget {
  const CustomerChatListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final myPhone = currentUser?.phone ?? profile.phone;
    final myName = currentUser?.name ?? profile.name;

    final allMessages = ref.watch(chatProvider);
    // Khách hàng chỉ thấy các tin nhắn có roomId bắt đầu bằng SĐT của mình
    final myMessages = allMessages.where((m) => m.roomId.startsWith(myPhone)).toList();

    final Map<String, ChatMessage> latestByRestaurant = {};
    for (final msg in myMessages) {
      latestByRestaurant[msg.restaurantName] = msg;
    }
    final restaurants = latestByRestaurant.values.toList().reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Tin nhắn hỗ trợ', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1D26), fontSize: 24)),
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        centerTitle: false,
      ),
      body: restaurants.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 72, color: Colors.black12),
                  SizedBox(height: 16),
                  Text('Bạn chưa có cuộc trò chuyện nào với nhà hàng.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final msg = restaurants[index];
                final isNeedReply = msg.senderRole == 'RESTAURANT';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isNeedReply ? const Color(0xFFFF5722).withOpacity(0.5) : Colors.transparent, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFFF5722).withOpacity(0.12),
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF5722)),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            msg.restaurantName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(msg.createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isNeedReply ? '${msg.restaurantName}: ${msg.content}' : 'Bạn: ${msg.content}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isNeedReply ? FontWeight.bold : FontWeight.normal,
                                color: isNeedReply ? const Color(0xFF1A1D26) : Colors.grey[600],
                              ),
                            ),
                          ),
                          if (isNeedReply)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFFF5722), borderRadius: BorderRadius.circular(10)),
                              child: const Text('Mới', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            roomId: msg.roomId,
                            restaurantName: msg.restaurantName,
                            customerName: myName,
                            currentRole: 'CUSTOMER',
                            currentSenderName: myName,
                            title: 'Chat với ${msg.restaurantName}',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// 4. HỘP THƯ DÀNH CHO NHÀ HÀNG (Hiển thị các Khách hàng đang Chat)
// ============================================================================
class RestaurantChatListView extends ConsumerWidget {
  final String staffName;
  const RestaurantChatListView({super.key, required this.staffName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final myRestaurant = currentUser?.restaurantName ?? '';

    final allMessages = ref.watch(chatProvider);
    // Nhà hàng chỉ thấy các tin nhắn gửi đến đúng tên nhà hàng của họ
    final restaurantMessages = allMessages.where((m) => m.restaurantName == myRestaurant).toList();

    final Map<String, ChatMessage> latestByRoom = {};
    for (final msg in restaurantMessages) {
      latestByRoom[msg.roomId] = msg;
    }
    final rooms = latestByRoom.values.toList().reversed.toList();

    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 72, color: Colors.black12),
            const SizedBox(height: 16),
            Text('Chưa có tin nhắn nào gửi tới $myRestaurant.', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final lastMsg = rooms[index];
        final isNeedReply = lastMsg.senderRole == 'CUSTOMER';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isNeedReply ? const Color(0xFFFF5722).withOpacity(0.5) : Colors.transparent, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFFF5722).withOpacity(0.12),
              child: Text(
                lastMsg.customerName.isNotEmpty ? lastMsg.customerName[0].toUpperCase() : 'K',
                style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${lastMsg.customerName} (${lastMsg.roomId.split('_')[0]})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(lastMsg.createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isNeedReply ? 'Khách: ${lastMsg.content}' : 'Bạn: ${lastMsg.content}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isNeedReply ? FontWeight.bold : FontWeight.normal,
                        color: isNeedReply ? const Color(0xFF1A1D26) : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (isNeedReply)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFF5722), borderRadius: BorderRadius.circular(10)),
                      child: const Text('Mới', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    roomId: lastMsg.roomId,
                    restaurantName: myRestaurant,
                    customerName: lastMsg.customerName,
                    currentRole: 'RESTAURANT',
                    currentSenderName: staffName,
                    title: 'Khách: ${lastMsg.customerName}',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}