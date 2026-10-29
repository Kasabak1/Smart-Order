import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:str/core/database/app_database.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedRole = 'CUSTOMER'; 
  bool _isLoading = false;

  @override void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  void _handleRegister() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin!'), backgroundColor: Colors.red));
      return;
    }
    if (ref.read(accountsDbProvider.notifier).phoneExists(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số điện thoại đã được đăng ký!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    // Chủ quán tạo tài khoản trống, sẽ khai báo tên quán sau khi đăng nhập
    await ref.read(accountsDbProvider.notifier).registerUser(name: name, phone: phone, password: pass, role: _selectedRole);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công! Đang chuyển về đăng nhập...'), backgroundColor: Color(0xFF00C853)));
      context.pop(); 
    }
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(controller: controller, obscureText: isPassword, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: Colors.grey), filled: true, fillColor: const Color(0xFFF4F6FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1D26)), onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tạo tài khoản', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: GestureDetector(onTap: () => setState(() => _selectedRole = 'CUSTOMER'), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _selectedRole == 'CUSTOMER' ? const Color(0xFFFF5722) : const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(16)), child: Center(child: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedRole == 'CUSTOMER' ? Colors.white : Colors.grey)))))),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(onTap: () => setState(() => _selectedRole = 'ADMIN'), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _selectedRole == 'ADMIN' ? const Color(0xFFFF5722) : const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(16)), child: Center(child: Text('Chủ Nhà hàng', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedRole == 'ADMIN' ? Colors.white : Colors.grey)))))),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(_nameCtrl, 'Họ và tên', Icons.person_outline_rounded),
              const SizedBox(height: 16),
              _buildTextField(_phoneCtrl, 'Số điện thoại', Icons.phone_android_rounded),
              const SizedBox(height: 16),
              _buildTextField(_passCtrl, 'Mật khẩu', Icons.lock_outline_rounded, isPassword: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ĐĂNG KÝ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}