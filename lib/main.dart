import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_router.dart';

// ============================================================================
// ĐIỀN URL VÀ ANON KEY TỪ TRANG SUPABASE CỦA BẠN VÀO ĐÂY:
// ============================================================================
const String supabaseUrl = 'https://mddalpadojitipwzdwqi.supabase.co';
const String supabaseAnonKey = 'sb_publishable_Vm5M8pjb4s9_xQqX7voaZw_LFlU8-00';

// Biến kiểm tra xem đã cấu hình Supabase thật hay chưa
bool isSupabaseConfigured = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (supabaseUrl.startsWith('https://') &&
        !supabaseUrl.contains('YOUR_PROJECT_ID') &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_PUBLIC_KEY') {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      isSupabaseConfigured = true;
      debugPrint('✅ Đã kết nối thành công tới Supabase Cloud!');
    } else {
      debugPrint('⚠️ Chưa điền Supabase Key -> Đang chạy chế độ Local Fallback.');
    }
  } catch (e) {
    debugPrint('❌ Lỗi khởi tạo Supabase: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Smart Order O2O',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}