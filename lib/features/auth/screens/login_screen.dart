import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    // Tài khoản Khách hàng
    if (phone == '0901111111' && password == '123456') {
      context.pushReplacement('/customer');
    } 
    // Tài khoản Chủ nhà hàng
    else if (phone == '0902222222' && password == '123456') {
      context.pushReplacement('/admin');
    } 
    // Tài khoản Nhân viên
    else if (phone == '0903333333' && password == '123456') {
      context.pushReplacement('/staff');
    } 
    // Sai thông tin
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sai số điện thoại hoặc mật khẩu!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.restaurant, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text('ĐĂNG NHẬP', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleLogin,
                child: const Text('ĐĂNG NHẬP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? '),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Đăng ký ngay'),
                  ),
                ],
              ),
              
              const Divider(height: 48),
              
              // Gợi ý tài khoản test hiển thị trực tiếp trên UI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🛠 Tài khoản Test (Mật khẩu: 123456)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    SizedBox(height: 8),
                    Text('• Khách hàng: 0901111111'),
                    Text('• Chủ nhà hàng: 0902222222'),
                    Text('• Nhân viên: 0903333333'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}