import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str/core/database/app_database.dart';

class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  void _showAddStaffDialog(BuildContext context, WidgetRef ref, String myRestaurant) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '123456');
    String selectedRole = 'Phục vụ bàn';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cấp tài khoản Nhân viên', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('Tên nhân viên'),
              _buildTextField(nameCtrl, 'Nhập họ và tên', Icons.person_outline),
              const SizedBox(height: 12),
              _buildInputLabel('Số điện thoại (TK Đăng nhập)'),
              _buildTextField(phoneCtrl, 'Nhập số điện thoại', Icons.phone_outlined, isPhone: true),
              const SizedBox(height: 12),
              _buildInputLabel('Mật khẩu'),
              _buildTextField(passCtrl, 'Nhập mật khẩu', Icons.lock_outline),
              const SizedBox(height: 12),
              _buildInputLabel('Chức vụ (Phân quyền)'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF5722)),
                    items: ['Phục vụ bàn', 'Bếp trưởng', 'Thu ngân'].map((role) {
                      return DropdownMenuItem(value: role, child: Text(role, style: const TextStyle(fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: (val) => selectedRole = val!,
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Color(0xFF6C7278), fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722), 
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
              elevation: 0
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
              if (ref.read(accountsDbProvider.notifier).phoneExists(phoneCtrl.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số điện thoại đã tồn tại!'), backgroundColor: Colors.redAccent));
                return;
              }
              
              // ĐÃ SỬA: Gắn đúng tên nhà hàng của Admin vào nhân viên mới
              ref.read(accountsDbProvider.notifier).registerUser(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    role: 'STAFF',
                    subRole: selectedRole,
                    restaurantName: myRestaurant, 
                  );
                  
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cấp tài khoản thành công!'), backgroundColor: Color(0xFF00C853), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('CẤP TÀI KHOẢN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6C7278))));
  
  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0B5B9), fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFFF4F6FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final myRestaurant = currentUser?.restaurantName ?? '';
    
    final allUsers = ref.watch(accountsDbProvider);
    // ĐÃ SỬA: Lọc chính xác Nhân viên thuộc Nhà hàng của Admin đang đăng nhập
    final staffList = allUsers.where((u) => u.role == 'STAFF' && u.restaurantName == myRestaurant).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Quản lý Nhân sự', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D26),
        elevation: 0.5,
        centerTitle: true,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
          boxShadow: [BoxShadow(color: const Color(0xFF1E88E5).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddStaffDialog(context, ref, myRestaurant),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Thêm nhân viên', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: staffList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Chưa có nhân viên nào', style: TextStyle(color: Color(0xFF9A9FA5), fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: Text(
                        staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'N', 
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E88E5), fontSize: 18)
                      ),
                    ),
                    title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(6)),
                          child: Text(staff.subRole, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6C7278))),
                        ),
                        const SizedBox(height: 6),
                        Text('SĐT: ${staff.phone} • MK: ${staff.password}', style: const TextStyle(fontSize: 12, color: Color(0xFF9A9FA5), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Xóa tài khoản?'),
                            content: Text('Bạn có chắc chắn muốn xóa nhân viên "${staff.name}" không?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                onPressed: () {
                                  ref.read(accountsDbProvider.notifier).deleteStaff(staff.id);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}