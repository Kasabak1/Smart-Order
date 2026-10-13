import 'package:flutter/material.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  // Danh sách nhân viên (Giả lập State)
  final List<Map<String, String>> _staffs = [
    {'name': 'Nguyễn Văn A', 'phone': '0903333333', 'role': 'Phục vụ bàn'},
  ];

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'Phục vụ bàn';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo tài khoản Nhân viên'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên nhân viên')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại (TK Đăng nhập)')),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Mật khẩu khởi tạo')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Chức vụ'),
                items: ['Phục vụ bàn', 'Bếp trưởng', 'Thu ngân'].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (val) => selectedRole = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _staffs.add({'name': nameCtrl.text, 'phone': phoneCtrl.text, 'role': selectedRole});
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo tài khoản thành công!')));
            },
            child: const Text('CẤP TÀI KHOẢN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Nhân sự'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm nhân viên', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _staffs.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final staff = _staffs[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(staff['name']![0], style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text('${staff['name']} - ${staff['role']}'),
            subtitle: Text('TK: ${staff['phone']} - Mật khẩu: ******'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() => _staffs.removeAt(index));
              },
            ),
          );
        },
      ),
    );
  }
}