import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:str/core/database/app_database.dart';

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  void _showAddDishDialog(BuildContext context, WidgetRef ref, String myRestaurant) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'Món chính';
    
    // Biến lưu ảnh được chọn
    XFile? selectedImage;
    bool isUploading = false; // Trạng thái đang tải lên

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Thêm món mới', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KHU VỰC CHỌN ẢNH
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (image != null) {
                          setDialogState(() => selectedImage = image);
                        }
                      },
                      child: Container(
                        height: 120, width: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2),
                          image: selectedImage != null
                              ? DecorationImage(
                                  // Hỗ trợ hiển thị ảnh trên cả Web và Điện thoại
                                  image: kIsWeb ? NetworkImage(selectedImage!.path) : FileImage(File(selectedImage!.path)) as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: selectedImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, color: Color(0xFFFF5722), size: 32),
                                  SizedBox(height: 8),
                                  Text('Thêm ảnh', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputLabel('Tên món ăn'),
                  _buildTextField(nameCtrl, 'VD: Cơm rang dưa bò'),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Giá bán (VNĐ)'),
                            _buildTextField(priceCtrl, '55000', isNumber: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Danh mục'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(14)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCategory, isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF5722)),
                                  items: ['Món chính', 'Món ăn nhẹ', 'Lẩu', 'Đồ uống', 'Tráng miệng'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))).toList(),
                                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInputLabel('Mô tả ngắn'),
                  _buildTextField(descCtrl, 'Mô tả nguyên liệu, hương vị...'),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              if (!isUploading)
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Color(0xFF6C7278), fontWeight: FontWeight.bold))),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), elevation: 0,
                ),
                onPressed: isUploading
                    ? null
                    : () async {
                        final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
                        if (nameCtrl.text.trim().isEmpty) return;

                        setDialogState(() => isUploading = true);

                        // Gọi hàm thêm món có đính kèm ảnh
                        await ref.read(menuDbProvider.notifier).addMenuItem(
                              name: nameCtrl.text.trim(),
                              price: price,
                              category: selectedCategory,
                              description: descCtrl.text.trim(),
                              restaurantName: myRestaurant,
                              imageFile: selectedImage, // Truyền file ảnh vào đây
                            );
                            
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm món mới thành công!'), backgroundColor: Color(0xFF00C853), behavior: SnackBarBehavior.floating));
                        }
                      },
                child: isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Thêm món', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6C7278))));
  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) => TextField(controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFFB0B5B9), fontWeight: FontWeight.normal), filled: true, fillColor: const Color(0xFFF4F6FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final myRestaurant = currentUser?.restaurantName ?? '';
    final menuList = ref.watch(menuDbProvider).where((m) => m.restaurantName == myRestaurant).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Quản lý Thực đơn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1D26), elevation: 0.5, centerTitle: true),
      floatingActionButton: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFFF5722)]), boxShadow: [BoxShadow(color: const Color(0xFFFF5722).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]),
        child: FloatingActionButton.extended(onPressed: () => _showAddDishDialog(context, ref, myRestaurant), backgroundColor: Colors.transparent, elevation: 0, icon: const Icon(Icons.add_rounded, color: Colors.white), label: const Text('Thêm món', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ),
      body: menuList.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey[300]), const SizedBox(height: 16), const Text('Thực đơn đang trống', style: TextStyle(color: Color(0xFF9A9FA5), fontSize: 16, fontWeight: FontWeight.w600))]))
          : ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100), itemCount: menuList.length,
              itemBuilder: (context, index) {
                final dish = menuList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
                  child: Row(
                    children: [
                      // HIỂN THỊ ẢNH THẬT
                      Container(
                        width: 75, height: 75,
                        decoration: BoxDecoration(
                          color: Colors.grey[200], borderRadius: BorderRadius.circular(16),
                          image: dish.imageUrl.isNotEmpty
                              ? DecorationImage(image: NetworkImage(dish.imageUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: dish.imageUrl.isEmpty ? Center(child: Text(dish.icon, style: const TextStyle(fontSize: 30))) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dish.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: dish.isAvailable ? const Color(0xFF1A1D26) : const Color(0xFF9A9FA5), decoration: dish.isAvailable ? null : TextDecoration.lineThrough)), const SizedBox(height: 4),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(6)), child: Text(dish.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6C7278)))), const SizedBox(height: 8),
                            Text('${dish.price} đ', style: TextStyle(color: dish.isAvailable ? const Color(0xFFFF5722) : Colors.grey, fontWeight: FontWeight.w900, fontSize: 15)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Switch(value: dish.isAvailable, activeColor: Colors.white, activeTrackColor: const Color(0xFF00C853), inactiveThumbColor: Colors.white, inactiveTrackColor: Colors.grey[300], onChanged: (_) => ref.read(menuDbProvider.notifier).toggleAvailability(dish.id)),
                          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 22), onPressed: () {
                              showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Xóa món ăn?'), content: Text('Bạn có chắc chắn muốn xóa "${dish.name}" khỏi thực đơn không?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { ref.read(menuDbProvider.notifier).deleteMenuItem(dish.id); Navigator.pop(ctx); }, child: const Text('Xóa', style: TextStyle(color: Colors.white)))]));
                            }),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}