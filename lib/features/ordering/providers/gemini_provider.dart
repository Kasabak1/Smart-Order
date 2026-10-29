import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:str/core/database/app_database.dart';

// ĐIỀN API KEY CỦA BẠN VÀO ĐÂY
const String _geminiApiKey = 'AIzaSyDwwgmF_fZ98tf_hVzdUlgYDXqXcIpY_O8'; 

class GeminiAssistantNotifier extends StateNotifier<String> {
  GeminiAssistantNotifier() : super('');

  // 1. Dùng trong MenuScreen (Chỉ gợi ý món ăn của 1 quán)
  Future<void> askForRecommendation(String userQuery, List<MenuItemModel> currentMenu, String restaurantName) async {
    if (currentMenu.isEmpty) {
      state = 'Hiện tại nhà hàng chưa có thực đơn để tôi gợi ý!';
      return;
    }
    state = 'Đang suy nghĩ...'; 
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _geminiApiKey);
      String menuContext = currentMenu.map((m) => '- ${m.name} (${m.price}đ): ${m.description}').join('\n');
      final prompt = '''
        Bạn là nhân viên tư vấn món ăn của nhà hàng "$restaurantName". 
        Dưới đây là thực đơn:
        $menuContext
        Khách hàng yêu cầu: "$userQuery"
        Nhiệm vụ: Dựa VÀO ĐÚNG THỰC ĐƠN TRÊN, chọn ra 1-2 món phù hợp nhất để giới thiệu. Trả lời dưới 100 chữ.
      ''';
      final response = await model.generateContent([Content.text(prompt)]);
      state = response.text ?? 'Xin lỗi, tôi không thể nghĩ ra món nào lúc này.';
    } catch (e) {
      state = 'Có lỗi kết nối đến AI. Vui lòng thử lại sau!';
    }
  }

  // 2. Dùng trong MainDashboardScreen (Quét toàn bộ hệ thống để tìm Quán + Món)
  Future<void> suggestRestaurantAndDish(String userQuery, String systemContext) async {
    state = 'AI đang lướt tìm nhà hàng ngon cho bạn...';
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _geminiApiKey);
      final prompt = '''
        Bạn là trợ lý ẩm thực thông minh của ứng dụng.
        Dưới đây là CÁC NHÀ HÀNG VÀ THỰC ĐƠN trên hệ thống:
        $systemContext
        
        Khách hàng yêu cầu: "$userQuery"
        
        Nhiệm vụ: Dựa ĐÚNG VÀO DỮ LIỆU TRÊN, hãy gợi ý 1 nhà hàng phù hợp nhất và 1-2 món ăn tiêu biểu của quán đó. 
        Tuyệt đối không bịa ra nhà hàng hoặc món ăn ngoài danh sách. Trả lời thân thiện, súc tích dưới 100 chữ.
      ''';
      final response = await model.generateContent([Content.text(prompt)]);
      state = response.text ?? 'Xin lỗi, tôi chưa tìm thấy nhà hàng nào phù hợp lúc này.';
    } catch (e) {
      state = 'Có lỗi kết nối đến AI. Vui lòng thử lại sau!';
    }
  }
}

final geminiAssistantProvider = StateNotifierProvider<GeminiAssistantNotifier, String>((ref) {
  return GeminiAssistantNotifier();
});