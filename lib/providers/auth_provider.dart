import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.post('auth/login.php', {
      'email': email,
      'password': password,
    });

    _isLoading = false;
    notifyListeners();

    // ব্যাকএন্ড status true বা success পাঠায় কিনা চেক
    if (res['status'] == true || res['status'] == 'success') {
      final user = res['user'];
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        if (user['organization_id'] != null) {
          await prefs.setInt('org_id', int.parse(user['organization_id'].toString()));
        }
        if (user['user_id'] != null) {
          await prefs.setInt('user_id', int.parse(user['user_id'].toString()));
        }
        if (user['email'] != null) {
          await prefs.setString('user_email', user['email'].toString());
        }
        if (user['full_name'] != null) {
          await prefs.setString('user_full_name', user['full_name'].toString());
        }
      }
      return {'success': true};
    } else {
      return {'success': false, 'message': res['message'] ?? 'ইমেইল বা পাসওয়ার্ড ভুল'};
    }
  }

  // লগইন থাকা ইউজারের ইমেইল ফিরিয়ে দেয় (পাসওয়ার্ড পরিবর্তনের জন্য দরকার হয়)
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = await getCurrentUserEmail();

    if (email == null || email.isEmpty) {
      return {'success': false, 'message': 'ইউজার শনাক্ত করা যায়নি, আবার লগইন করুন।'};
    }

    final res = await ApiService.post('auth/change_password.php', {
      'email': email,
      'current_password': currentPassword,
      'new_password': newPassword,
    });

    if (res['status'] == true) {
      return {'success': true, 'message': res['message'] ?? 'পাসওয়ার্ড পরিবর্তন করা হয়েছে।'};
    } else {
      return {'success': false, 'message': res['message'] ?? 'পাসওয়ার্ড পরিবর্তন করা যায়নি।'};
    }
  }
}
