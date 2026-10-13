import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đăng ký tài khoản'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Khách hàng'),
              Tab(text: 'Chủ nhà hàng'),
            ],
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
          ),
        ),
        body: const TabBarView(
          children: [
            _CustomerRegisterForm(),
            _ManagerRegisterForm(),
          ],
        ),
      ),
    );
  }
}

class _CustomerRegisterForm extends StatelessWidget {
  const _CustomerRegisterForm();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const TextField(decoration: InputDecoration(labelText: 'Họ và tên')),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: 'Số điện thoại')),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () {}, child: const Text('TẠO TÀI KHOẢN KHÁCH HÀNG')),
      ],
    );
  }
}

class _ManagerRegisterForm extends StatelessWidget {
  const _ManagerRegisterForm();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Thông tin Quản lý', style: TextStyle(fontWeight: FontWeight.bold)),
        const TextField(decoration: InputDecoration(labelText: 'Họ tên Chủ quán')),
        const TextField(decoration: InputDecoration(labelText: 'Số điện thoại đăng nhập')),
        const SizedBox(height: 16),
        const Text('Thông tin Cửa hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        const TextField(decoration: InputDecoration(labelText: 'Tên nhà hàng/Quán ăn')),
        const TextField(decoration: InputDecoration(labelText: 'Địa chỉ chi tiết')),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          onPressed: () {}, 
          child: const Text('ĐĂNG KÝ MỞ QUÁN'),
        ),
      ],
    );
  }
}