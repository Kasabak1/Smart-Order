import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:str/core/database/app_database.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _handleLogin() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final user = ref.read(accountsDbProvider.notifier).login(phone, password);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Số điện thoại hoặc mật khẩu không chính xác!')),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    // Lấy user vừa đăng nhập      
        ref.read(currentUserProvider.notifier).state = user;
        
        // ĐIỀU HƯỚNG THEO VAI TRÒ
        if (user.role == 'SUPER_ADMIN') {
          context.pushReplacement('/super-admin'); // Chuyển tới SuperAdminDashboardScreen
        } else if (user.role == 'ADMIN') {
          context.pushReplacement('/admin');
        } else if (user.role == 'STAFF' || user.role == 'WAITER' || user.role == 'CHEF') {
          context.pushReplacement('/staff');
        } else {
          context.pushReplacement('/customer');
        }
    
  }

  @override
  Widget build(BuildContext context) {
    final allAccounts = ref.watch(accountsDbProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO BANNER CHUẨN FIGMA
            Stack(
              children: [
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1000&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.black.withOpacity(0.3),
                        const Color(0xFFFF5722).withOpacity(0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Nền tảng Nhà hàng O2O thế hệ mới',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Smart Order.',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Đặt bàn nhanh chóng • Gọi món tại bàn • Đồng bộ Bếp & Phục vụ thời gian thực.',
                          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // FLOATING LOGIN CARD
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Chào mừng trở lại 👋',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1D26)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đăng nhập để tiếp tục vào không gian của bạn',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9A9FA5)),
                    ),
                    const SizedBox(height: 24),
                    _buildInputLabel('Số điện thoại'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Nhập số điện thoại...',
                        hintStyle: const TextStyle(color: Color(0xFFB0B5B9), fontWeight: FontWeight.normal),
                        prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFFFF5722)),
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildInputLabel('Mật khẩu'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: Color(0xFFB0B5B9)),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFF5722)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF9A9FA5),
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _handleLogin,
                        child: const Text(
                          'Đăng nhập ngay',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Chưa có tài khoản? ', style: TextStyle(color: Color(0xFF6C7278))),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: const Text(
                            'Tạo tài khoản mới',
                            style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // QUICK LOGIN DEMO CHIPS (NẾU TRÊN SUPABASE ĐÃ CÓ TÀI KHOẢN)
            if (allAccounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: Color(0xFFFF5722), size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Chạm để điền nhanh tài khoản từ Supabase:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6C7278)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: allAccounts.map((acc) {
                        final isManager = acc.role == 'ADMIN';
                        final isStaff = acc.role == 'STAFF';
                        final badgeColor = isManager
                            ? const Color(0xFFE53935)
                            : isStaff
                                ? const Color(0xFF00897B)
                                : const Color(0xFF1E88E5);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _phoneController.text = acc.phone;
                              _passwordController.text = acc.password;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: badgeColor.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: badgeColor.withOpacity(0.12),
                                  child: Icon(
                                    isManager
                                        ? Icons.workspace_premium
                                        : isStaff
                                            ? Icons.restaurant_menu
                                            : Icons.person,
                                    size: 14,
                                    color: badgeColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    Text(
                                      '${acc.role}${acc.subRole.isNotEmpty ? " • ${acc.subRole}" : ""}',
                                      style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D26)),
    );
  }
}