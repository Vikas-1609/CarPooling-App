
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart'; // To handle token deletion on logout

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isAuthenticated = false;
  final AuthService _authService = AuthService(); // Instance to manage token

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  void setUser(UserModel user) {
    _user = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> checkAuthenticationStatus() async {
    final token = await _authService.getToken();
    final isValid = await _authService.isTokenValid();

    if (token != null && isValid && _user == null) {
      try {
        _user = await _authService.getCurrentUser();
        _isAuthenticated = true;
      } catch (e) {
        _isAuthenticated = false;
        await _authService.deleteToken();
      }
    } else if (token != null && !isValid) {
      _isAuthenticated = false;
      await _authService.deleteToken();
    } else if (_user != null) {
      _isAuthenticated = true;
    }
    notifyListeners();
  }

  void logout() async {
    await _authService.deleteToken(); // Delete token from secure storage
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
