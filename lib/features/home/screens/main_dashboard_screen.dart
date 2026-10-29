import 'dart:math' show cos, sqrt, asin;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:str/core/database/app_database.dart';
import 'package:str/features/staff/providers/staff_provider.dart';
import 'package:str/features/chat/chat_screen.dart';
import 'package:str/features/ordering/providers/gemini_provider.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:http/http.dart' as http; 

// ============================================================================
// 1. CÔNG THỨC TOÁN HỌC TÍNH KHOẢNG CÁCH
// ============================================================================
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)); 
}

class UserProfile {
  final String name, phone, email, address;
  final double lat, lng; 
  UserProfile({required this.name, required this.phone, required this.email, required this.address, this.lat = 21.0031, this.lng = 105.8202});
  UserProfile copyWith({String? name, String? phone, String? email, String? address}) => UserProfile(name: name ?? this.name, phone: phone ?? this.phone, email: email ?? this.email, address: address ?? this.address, lat: lat, lng: lng);
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile(name: 'Nguyễn Văn Khách', phone: '0901111111', email: 'khachhang@smartorder.vn', address: 'Cầu Giấy, Hà Nội'));
  void updateProfile({required String name, required String phone, required String email, required String address}) { state = state.copyWith(name: name, phone: phone, email: email, address: address); }
}
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) => UserProfileNotifier());

// ============================================================================
// 2. MÀN HÌNH CHÍNH KHÁCH HÀNG
// ============================================================================
class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});
  @override ConsumerState<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Lẩu & Thái', 'Món Âu', 'Đặc sản Việt', 'Buffet Lẩu'];
  
  final TextEditingController _aiTextCtrl = TextEditingController();
  LatLng? _customerRealPos;
  String _currentAddress = 'Đang định vị...';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng bật GPS trên điện thoại!')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    if (mounted) {
      setState(() {
        _customerRealPos = LatLng(position.latitude, position.longitude);
      });
      
      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
        final response = await http.get(url, headers: {
          'User-Agent': 'com.smartorder.app',
          'Accept-Language': 'vi-VN,vi;q=0.9',
        });

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final address = data['address'];
          
          if (address != null) {
            final road = address['road'] ?? address['pedestrian'] ?? address['suburb'] ?? '';
            final city = address['city'] ?? address['county'] ?? address['state'] ?? 'Hà Nội';
            
            setState(() {
              _currentAddress = '$road, $city'.trim();
              if (_currentAddress.startsWith(',')) _currentAddress = city;
            });
          }
        }
      } catch (e) {
        setState(() {
          _currentAddress = 'Không thể xác định tên đường';
        });
      }
    }
  }

  @override
  void dispose() {
    _aiTextCtrl.dispose();
    super.dispose();
  }

  void _sendAIQuery() {
    final query = _aiTextCtrl.text.trim();
    if (query.isNotEmpty) {
      final restaurants = ref.watch(realRestaurantListProvider);
      final allMenus = ref.read(menuDbProvider);
      String systemContext = '';
      
      for (var res in restaurants) {
        systemContext += 'Nhà hàng: ${res.name} (Chuyên: ${res.category})\n';
        final resMenu = allMenus.where((m) => m.restaurantName == res.name).toList();
        if (resMenu.isNotEmpty) {
          systemContext += 'Thực đơn: ' + resMenu.map((m) => '${m.name} (${m.price}đ)').join(', ') + '\n';
        } else {
          systemContext += 'Thực đơn: Đang cập nhật\n';
        }
        systemContext += '-------------------\n';
      }
      
      ref.read(geminiAssistantProvider.notifier).suggestRestaurantAndDish(query, systemContext);
      _aiTextCtrl.clear();
      FocusScope.of(context).unfocus(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider);
    final myName = currentUser?.name ?? profile.name;
    
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final List<Widget> pages = [
      _buildExploreTab(myName, profile),
      _buildHistoryTab(),
      _buildAITab(), 
      const CustomerChatListView(), 
      _buildProfileTab(), 
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: pages[_currentIndex],
      
      floatingActionButton: (_currentIndex == 0 && !isKeyboardOpen)
          ? Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFFF5722)]), boxShadow: [BoxShadow(color: const Color(0xFFFF5722).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]),
              child: FloatingActionButton.extended(onPressed: () => context.pushNamed('scanQR'), backgroundColor: Colors.transparent, elevation: 0, icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white), label: const Text('Quét QR tại bàn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            )
          : null,
          
      bottomNavigationBar: isKeyboardOpen 
        ? null 
        : Container(
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4))]),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.white, elevation: 0, indicatorColor: const Color(0xFFFF5722).withOpacity(0.12),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.compass_calibration_outlined), selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFFFF5722)), label: 'Khám phá'),
                NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFFFF5722)), label: 'Lịch đặt'),
                NavigationDestination(icon: Icon(Icons.auto_awesome_outlined, color: Colors.purple), selectedIcon: Icon(Icons.auto_awesome, color: Colors.purple), label: 'Trợ lý AI'),
                NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFFFF5722)), label: 'Hỗ trợ'),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: Color(0xFFFF5722)), label: 'Hồ sơ'),
              ],
            ),
          ),
    );
  }

  Widget _buildAITab() {
    final answer = ref.watch(geminiAssistantProvider);
    Color textColor = const Color(0xFF1A1D26);
    if (answer.contains('❌ LỖI')) textColor = Colors.red;
    if (answer.contains('Đang lướt tìm')) textColor = Colors.orange.shade800;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text('Trợ lý Ẩm thực AI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1D26))),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))]
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 36),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        answer.isEmpty ? 'Xin chào! Bạn đang thèm món gì, hay muốn tìm quán có không gian ra sao? Hãy nhắn cho tôi nhé!' : answer,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15, 
                          color: textColor,
                          fontStyle: answer.isEmpty ? FontStyle.italic : FontStyle.normal, 
                          height: 1.6
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4))]
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _aiTextCtrl,
                      onSubmitted: (_) => _sendAIQuery(), 
                      decoration: InputDecoration(
                        hintText: 'VD: Gợi ý quán lẩu thái ngon...',
                        filled: true,
                        fillColor: const Color(0xFFF4F6FA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendAIQuery,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExploreTab(String displayName, UserProfile profile) {
    final restaurants = ref.watch(realRestaurantListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final myPhone = currentUser?.phone ?? profile.phone;
    
    final filteredList = restaurants.where((r) {
      if (r.status != 'APPROVED') return false; 
      
      final matchesSearch = r.name.toLowerCase().contains(_searchQuery.toLowerCase()) || r.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Tất cả' || r.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const Text('Xin chào,', style: TextStyle(fontSize: 14, color: Color(0xFF6C7278))),
                  const SizedBox(height: 2),
                  Text('$displayName 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1D26))),
                ]
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end, 
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.my_location_rounded, color: Color(0xFF00897B), size: 14), 
                        const SizedBox(width: 4), 
                        const Text('Vị trí của bạn', style: TextStyle(fontSize: 12, color: Color(0xFF6C7278), fontWeight: FontWeight.w600)),
                      ]
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentAddress, 
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1D26))
                    ),
                  ]
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(hintText: 'Tìm nhà hàng...', hintStyle: const TextStyle(color: Color(0xFFA0A5BA), fontSize: 14), prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF5722)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          
          const SizedBox(height: 22),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal, itemCount: _categories.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(color: isSelected ? const Color(0xFFFF5722) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [if (isSelected) BoxShadow(color: const Color(0xFFFF5722).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]), child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF6C7278), fontWeight: FontWeight.bold, fontSize: 13))),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          
          ...filteredList.map((restaurant) {
            double userLat = _customerRealPos?.latitude ?? profile.lat;
            double userLng = _customerRealPos?.longitude ?? profile.lng;
            double distanceKm = calculateDistance(userLat, userLng, restaurant.lat, restaurant.lng);
            
            return Container(
                margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.network(restaurant.imageUrl, height: 175, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 175, color: Colors.orange[100], child: const Center(child: Icon(Icons.restaurant, size: 50, color: Colors.deepOrange)))),
                          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.55)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
                          Positioned(top: 14, left: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(20)), child: Text(restaurant.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
                          Positioned(
                            top: 14, right: 14, 
                            child: GestureDetector(
                              onTap: () => _showReviewsBottomSheet(context, ref, restaurant, displayName),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]), 
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18), 
                                    const SizedBox(width: 4), 
                                    Consumer(builder: (context, ref, child) {
                                      final resReviews = ref.watch(reviewsProvider).where((r) => r.restaurantName == restaurant.name).toList();
                                      final avgRating = resReviews.isEmpty ? restaurant.rating : (resReviews.map((r) => r.rating).reduce((a, b) => a + b) / resReviews.length);
                                      return Text('${avgRating.toStringAsFixed(1)} (${resReviews.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13));
                                    })
                                  ]
                                )
                              ),
                            )
                          ),
                          Positioned(bottom: 12, right: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF00897B), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.directions_car_rounded, color: Colors.white, size: 14), const SizedBox(width: 4), Text('${distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]))),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(restaurant.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1A1D26))),
                            const SizedBox(height: 8),
                            Row(children: [const Icon(Icons.place_outlined, size: 16, color: Color(0xFFFF5722)), const SizedBox(width: 6), Expanded(child: Text(restaurant.address, style: const TextStyle(color: Color(0xFF6C7278), fontSize: 13)))]),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: const Color(0xFFFF5722).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                  child: IconButton(
                                    icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFFFF5722), size: 22),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(roomId: '${myPhone}_${restaurant.name}', restaurantName: restaurant.name, customerName: displayName, currentRole: 'CUSTOMER', currentSenderName: displayName, title: 'Chat với ${restaurant.name}')));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(14)),
                                  child: IconButton(
                                    icon: const Icon(Icons.map_outlined, color: Color(0xFF1E88E5), size: 22),
                                    onPressed: () => _showMapBottomSheet(context, restaurant, profile),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), 
                                    onPressed: () => _showBookingSheet(context, restaurant, profile), 
                                    icon: const Icon(Icons.event_seat_rounded, size: 18), 
                                    label: const Text('Đặt bàn', style: TextStyle(fontWeight: FontWeight.bold))
                                  )
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
          }).toList(),
        ],
      ),
    );
  }

  void _showMapBottomSheet(BuildContext context,RestaurantModel restaurant, UserProfile profile) {
    final customerPos = _customerRealPos ?? LatLng(profile.lat, profile.lng);
    final restaurantPos = LatLng(restaurant.lat, restaurant.lng);
    
    double preciseDistanceKm = calculateDistance(customerPos.latitude, customerPos.longitude, restaurantPos.latitude, restaurantPos.longitude);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chỉ đường đến nhà hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF00897B).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('Cách bạn ${preciseDistanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(),
            
            Expanded(
              child: ClipRRect(
                child: _customerRealPos == null 
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Đang lấy vị trí của bạn...')]))
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: _customerRealPos!, 
                        initialZoom: 14.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.smartorder.app',
                        ),
                        PolylineLayer<Object>( 
                          polylines: [
                            Polyline(
                              points: [_customerRealPos!, restaurantPos],
                              color: const Color(0xFF1E88E5),
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _customerRealPos!,
                              width: 40, height: 40,
                              child: const Icon(Icons.person_pin_circle_rounded, color: Colors.blue, size: 40),
                            ),
                            Marker(
                              point: restaurantPos,
                              width: 40, height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () => Navigator.pop(context), icon: const Icon(Icons.navigation_rounded), label: const Text('Đóng bản đồ', style: TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context, RestaurantModel restaurant, UserProfile profile) {
    DateTime selectedDate = DateTime.now(); TimeOfDay selectedTime = const TimeOfDay(hour: 19, minute: 0); int guests = 2;
    final noteController = TextEditingController(); 
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  Text('Đặt bàn giữ chỗ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                  const SizedBox(height: 4),
                  Text(restaurant.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(restaurant.address, style: const TextStyle(color: Color(0xFF6C7278), fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: InkWell(onTap: () async { final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30))); if (picked != null) setModalState(() => selectedDate = picked); }, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF6F7FB), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.calendar_month_rounded, color: Color(0xFFFF5722), size: 20), const SizedBox(width: 8), Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.bold))])))),
                      const SizedBox(width: 12),
                      Expanded(child: InkWell(onTap: () async { final picked = await showTimePicker(context: context, initialTime: selectedTime); if (picked != null) setModalState(() => selectedTime = picked); }, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF6F7FB), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.access_time_filled_rounded, color: Color(0xFFFF5722), size: 20), const SizedBox(width: 8), Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold))])))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF6F7FB), borderRadius: BorderRadius.circular(14)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Số lượng khách tham dự', style: TextStyle(fontWeight: FontWeight.w700)), Row(children: [IconButton(onPressed: guests > 1 ? () => setModalState(() => guests--) : null, icon: const Icon(Icons.remove_circle_outline)), Text('$guests người', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), IconButton(onPressed: () => setModalState(() => guests++), icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFFF5722)))])]),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: noteController, decoration: InputDecoration(hintText: 'Ghi chú (VD: Bàn gần cửa sổ...)', filled: true, fillColor: const Color(0xFFF6F7FB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () {
                        ref.read(reservationProvider.notifier).addReservation(customerName: profile.name, customerPhone: profile.phone, restaurantName: restaurant.name, address: restaurant.address, date: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', time: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}', guests: guests, note: noteController.text.trim());
                        Navigator.pop(context); setState(() => _currentIndex = 1);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu đặt bàn!'), backgroundColor: Color(0xFF00C853), behavior: SnackBarBehavior.floating));
                      },
                      child: const Text('XÁC NHẬN ĐẶT BÀN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final reservations = ref.watch(reservationProvider);
    final activeList = reservations.where((r) => r.status == 'PENDING' || r.status == 'CONFIRMED').toList();
    final cancelledList = reservations.where((r) => r.status == 'CANCELLED').toList();

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 12), child: Text('Lịch đặt bàn của bạn', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1D26)))),
            Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: TabBar(labelColor: const Color(0xFFFF5722), unselectedLabelColor: const Color(0xFF9A9FA5), indicatorColor: const Color(0xFFFF5722), labelStyle: const TextStyle(fontWeight: FontWeight.bold), tabs: [Tab(text: 'Sắp tới (${activeList.length})'), Tab(text: 'Đã hủy (${cancelledList.length})')])),
            const SizedBox(height: 8),
            Expanded(child: TabBarView(children: [_buildReservationList(activeList, isActive: true), _buildReservationList(cancelledList, isActive: false)])),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationList(List<Reservation> list, {required bool isActive}) {
    if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isActive ? Icons.calendar_month_outlined : Icons.event_busy_outlined, size: 80, color: Colors.grey[300]), const SizedBox(height: 16), Text(isActive ? 'Chưa có lịch đặt bàn nào' : 'Không có đơn bị hủy', style: const TextStyle(color: Color(0xFF9A9FA5), fontSize: 15, fontWeight: FontWeight.w600))]));

    return ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isPending = item.status == 'PENDING';
        return Container(
          margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(item.restaurantName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isPending ? const Color(0xFFFFF8E1) : (item.status == 'CONFIRMED' ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)), borderRadius: BorderRadius.circular(20)), child: Text(isPending ? '⏳ Chờ xếp bàn' : (item.status == 'CONFIRMED' ? '✓ Đã xếp: ${item.assignedTable}' : 'Đã hủy'), style: TextStyle(color: isPending ? const Color(0xFFF57C00) : (item.status == 'CONFIRMED' ? const Color(0xFF2E7D32) : const Color(0xFFE53935)), fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 6),
              Text(item.address, style: const TextStyle(color: Color(0xFF6C7278), fontSize: 13)),
              Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.grey[200], height: 1)),
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.calendar_month, size: 20, color: Colors.orange)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Thời gian', style: TextStyle(color: Colors.grey[500], fontSize: 12)), Text('${item.time} - ${item.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                  const Spacer(),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.people, size: 20, color: Colors.blue)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Số khách', style: TextStyle(color: Colors.grey[500], fontSize: 12)), Text('${item.guests} người', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                ],
              ),
              if (item.note.isNotEmpty) ...[const SizedBox(height: 16), Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)), child: Text('Ghi chú: ${item.note}', style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic, fontSize: 13)))],
              if (isActive) ...[const SizedBox(height: 14), SizedBox(width: double.infinity, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE53935), side: const BorderSide(color: Color(0xFFFFCDD2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () => ref.read(reservationProvider.notifier).cancelReservation(item.id), child: const Text('Hủy đặt bàn', style: TextStyle(fontWeight: FontWeight.bold))))],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final profile = ref.watch(userProfileProvider);
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.only(top: 60, bottom: 36), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFFF5722)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.vertical(bottom: Radius.circular(36))),
            child: Column(children: [const CircleAvatar(radius: 46, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, size: 54, color: Color(0xFFFF5722))), const SizedBox(height: 14), Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)), const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: const Text('👑 Thành viên Hạng Vàng', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(children: [
                    ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: const Icon(Icons.phone_iphone_rounded, color: Colors.blue, size: 20)), title: const Text('Số điện thoại', style: TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(profile.phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    Divider(height: 1, color: Colors.grey[200], indent: 64),
                    ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle), child: const Icon(Icons.mail_outline_rounded, color: Colors.red, size: 20)), title: const Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(profile.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    Divider(height: 1, color: Colors.grey[200], indent: 64),
                    ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle), child: const Icon(Icons.location_on_outlined, color: Colors.green, size: 20)), title: const Text('Địa chỉ', style: TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(profile.address, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  ]),
                ),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE53935), side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => context.pushReplacement('/'), icon: const Icon(Icons.logout_rounded), label: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

  void _showReviewsBottomSheet(BuildContext context, WidgetRef ref, RestaurantModel restaurant, String myName) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            children: [
              Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Đánh giá & Nhận xét', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => _showWriteReviewDialog(context, ref, restaurant.name, myName),
                      icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Viết đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final reviews = ref.watch(reviewsProvider).where((r) => r.restaurantName == restaurant.name).toList();
                    if (reviews.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey[300]), const SizedBox(height: 16), const Text('Chưa có đánh giá nào.\nHãy là người đầu tiên nhận xét!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))]));
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(20), itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final rev = reviews[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(backgroundColor: Colors.blue.shade100, radius: 16, child: Text(rev.userName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(rev.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                  Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 16, color: i < rev.rating ? Colors.amber : Colors.grey.shade300))),
                                ],
                              ),
                              if (rev.comment.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(rev.comment, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
                              ]
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWriteReviewDialog(BuildContext context, WidgetRef ref, String restaurantName, String myName) {
    int selectedStars = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Đánh giá trải nghiệm', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(restaurantName, style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(Icons.star_rounded, size: 36, color: index < selectedStars ? Colors.amber : Colors.grey.shade300),
                      onPressed: () => setDialogState(() => selectedStars = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(controller: commentCtrl, maxLines: 3, decoration: InputDecoration(hintText: 'Nhà hàng phục vụ thế nào? Đồ ăn có ngon không?', filled: true, fillColor: const Color(0xFFF4F6FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  final success = await ref.read(reviewsProvider.notifier).addReview(
                    restaurantName, myName, selectedStars, commentCtrl.text.trim()
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context); 
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!'), backgroundColor: Color(0xFF00C853)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Chưa thể lưu đánh giá. Hãy kiểm tra lại SQL!'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('GỬI ĐÁNH GIÁ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }