import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/result.dart';
import '../../core/exceptions.dart';
import '../../core/logger.dart';
import '../auth_repository.dart';
import '../../models/user.dart';
import '../api_user_database.dart';

/// Auth Repository that uses backend API for MySQL database operations
class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  final StreamController<User?> _userController = StreamController<User?>.broadcast();
  static const String _userEmailKey = 'user_email';

  @override
  Future<Result<User>> login(String email, String password, {bool rememberMe = false}) async {
    try {
      AppLogger.auth('Login attempt for: $email');
      
      // Use API service
      final user = await ApiUserDatabase.login(email, password);
      if (user == null) {
        return Result.failure(const AuthException('Invalid credentials', code: 'INVALID_CREDENTIALS'));
      }

      _currentUser = user;
      _userController.add(user);

      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userEmailKey, email);
      }

      AppLogger.auth('Login successful for: $email');
      return Result.success(user);
    } catch (e) {
      AppLogger.auth('Login failed', error: e);
      return Result.failure(AuthException('Login failed', originalError: e));
    }
  }

  @override
  Future<Result<User>> register(String name, String email, String password, {bool rememberMe = false}) async {
    try {
      AppLogger.auth('Register attempt for: $email');
      
      try {
        // Use API service
        final user = await ApiUserDatabase.register(name: name, email: email, password: password);
         
         if (user != null) {
           _currentUser = user;
           _userController.add(user);
           
           if (rememberMe) {
             final prefs = await SharedPreferences.getInstance();
             await prefs.setString(_userEmailKey, email);
           }
           
           AppLogger.auth('Registration successful for: $email');
           return Result.success(user);
         } else {
             return Result.failure(const DataException('Registration returned null'));
         }
      } catch (e) {
        if (e.toString().contains('exists')) {
             return Result.failure(const AuthException('User already exists', code: 'EMAIL_EXISTS'));
        }
        rethrow;
      }
    } catch (e) {
      AppLogger.auth('Registration failed', error: e);
      return Result.failure(AuthException('Registration failed', originalError: e));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      if (_currentUser != null) return Result.success(_currentUser);

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_userEmailKey);
      
      if (email != null) {
        // Use API service
        final user = await ApiUserDatabase.getUser(email);
        if (user != null) {
          _currentUser = user;
          _userController.add(user);
          return Result.success(user);
        }
      }
      return Result.success(null);
    } catch (e) {
      AppLogger.auth('Get current user failed', error: e);
      return Result.failure(CacheException('Failed to restore session', originalError: e));
    }
  }
  
  @override
  Future<Result<void>> logout() async {
    _currentUser = null;
    _userController.add(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    AppLogger.auth('Logout successful');
    return Result.success(null);
  }

  @override
  Future<Result<User>> updateUser(User user) async {
    try {
        // Use API service
        final updated = await ApiUserDatabase.updateUser(user);
        if (updated != null) {
            _currentUser = updated;
            _userController.add(updated);
            return Result.success(updated);
        }
        return Result.failure(const DataException('User not found'));
    } catch (e) {
        AppLogger.auth('Update user failed', error: e);
        return Result.failure(DataException('Update failed', originalError: e));
    }
  }

  @override
  Future<Result<void>> changePassword(String current, String newPass) async {
     try {
       if (_currentUser == null) return Result.failure(const AuthException('Not logged in'));
       
       // Use API service
       final success = await ApiUserDatabase.changePassword(_currentUser!.email, current, newPass);
       if (success) {
         AppLogger.auth('Password changed for: ${_currentUser!.email}');
         return Result.success(null);
       }
       return Result.failure(const AuthException('Password change failed (verify current password)'));
     } catch (e) {
        return Result.failure(DataException('Error changing password', originalError: e));
     }
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    // Mock implementation - in production, send email
    AppLogger.auth('Password reset requested for: $email');
    return Result.success(null);
  }

  @override
  Stream<User?> watchUser() {
      return _userController.stream;
  }
}