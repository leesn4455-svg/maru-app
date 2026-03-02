// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://maruieum.com/api.php';

  static Future<List<dynamic>> getNotices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_notices'));
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getSites() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_sites'));
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> login(String loginId, String password) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl?action=login'), body: {'login_id': loginId, 'password': password});
      return json.decode(response.body);
    } catch (e) { return {'status': 'error', 'message': '네트워크 오류가 발생했습니다.'}; }
  }

  static Future<Map<String, dynamic>> register(String loginId, String password, String name, String phone) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl?action=register'), body: {'login_id': loginId, 'password': password, 'name': name, 'phone': phone});
      return json.decode(response.body);
    } catch (e) { return {'status': 'error', 'message': '네트워크 오류가 발생했습니다.'}; }
  }

  static Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_users'));
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) { return []; }
  }

  // 🌟 [추가됨] 채팅 메시지 50개 불러오기
  static Future<List<dynamic>> getChats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_chats'));
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) { return []; }
  }

  // 🌟 [추가됨] 채팅 메시지 서버로 전송하기
  static Future<bool> sendChat(String senderId, String senderName, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=send_chat'),
        body: {'sender_id': senderId, 'sender_name': senderName, 'message': message},
      );
      final result = json.decode(response.body);
      return result['status'] == 'success';
    } catch (e) { return false; }
  }

  // 🌟 [추가됨] 앱에서 내 스케줄 가져오기 API
  static Future<List<dynamic>> getSchedules(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_schedules&user_id=$userId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) { return []; }
  }
}