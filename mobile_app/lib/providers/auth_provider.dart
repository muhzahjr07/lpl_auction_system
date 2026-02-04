import 'package:flutter/material.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _userRole;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get userRole => _userRole;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null; // Reset error
    notifyListeners();

    final result = await _apiService.login(email, password);

    _isLoading = false;
    if (result['success']) {
      _userRole = result['role'];
      _errorMessage = null;
    } else {
      _errorMessage = result['message'];
    }

    notifyListeners();
    return result['success'];
  }

  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    // Clear session
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _userRole = null;
    _isLoading = false;
    notifyListeners();

    // Navigate to Login
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
}
