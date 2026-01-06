import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/result.dart';
import '../../core/exceptions.dart';
import '../../core/logger.dart';
import '../auth_repository.dart';
import '../../models/user.dart';

class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  static const String _userKey = 'current_user';
  static const String _authTokenKey = 'auth_token';
  
  final StreamController<User?> _userController = StreamController<User?>.broadcast();
  
  static const String _passwordsKey = 'mock_passwords';
  static const String _profilesKey = 'mock_profiles';
  
  final Map<String, String> _mockUsers = {
    'student@university.edu': 'password123',
    'professor@university.edu': 'password123',
    'test@example.com': 'password123',
  };

  final Map<String, User> _persistedProfiles = {};

  Future<void> _initFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Passwords
    final storedPasswords = prefs.getString(_passwordsKey);
    if (storedPasswords != null) {
      final Map<String, dynamic> decoded = jsonDecode(storedPasswords);
      decoded.forEach((key, value) {
        _mockUsers[key] = value.toString();
      });
    }

    // Load Profiles
    final storedProfiles = prefs.getString(_profilesKey);
    if (storedProfiles != null) {
      final Map<String, dynamic> decoded = jsonDecode(storedProfiles);
      decoded.forEach((key, value) {
        _persistedProfiles[key] = User.fromJson(value as Map<String, dynamic>);
      });
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordsKey, jsonEncode(_mockUsers));
    
    final profilesMap = _persistedProfiles.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_profilesKey, jsonEncode(profilesMap));
  }

  void _emitUser(User? user) {
    _userController.add(user);
  }

  @override
  Future<Result<User>> login(String email, String password, {bool rememberMe = false}) async {
    try {
      AppLogger.auth('Login attempt for email: $email');
      
      await _initFromStorage();
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!_mockUsers.containsKey(email)) {
        return Result.failure(const AuthException('Invalid email or password', code: 'INVALID_CREDENTIALS'));
      }
      
      if (_mockUsers[email] != password) {
        return Result.failure(const AuthException('Invalid email or password', code: 'INVALID_CREDENTIALS'));
      }
      
      User user;
      if (_persistedProfiles.containsKey(email)) {
        user = _persistedProfiles[email]!;
      } else {
        // Create a new profile based on the template but with the correct email/name
        final template = await _loadUserFromAsset();
        final namePrefix = email.split('@').first;
        final capitalizedName = namePrefix[0].toUpperCase() + namePrefix.substring(1);
        
        user = template.copyWith(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: capitalizedName,
          isOnboardingComplete: false,
        );
        _persistedProfiles[email] = user;
        await _saveToStorage();
      }

      final updatedUser = user.copyWith(
        authToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        rememberMe: rememberMe,
      );
      
      _currentUser = updatedUser;
      _emitUser(_currentUser);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      
      if (rememberMe) {
        await prefs.setString(_authTokenKey, updatedUser.authToken!);
        await prefs.setString('user_email', email);
        await prefs.setString('user_password', password);
      }
      
      AppLogger.auth('Login successful for email: $email');
      return Result.success(updatedUser);
    } catch (e) {
      AppLogger.auth('Login failed', error: e);
      return Result.failure(
        DataException('Login failed', originalError: e),
      );
    }
  }

  @override
  Future<Result<User>> register(String name, String email, String password, {bool rememberMe = false}) async {
    try {
      AppLogger.auth('Registration attempt for email: $email');
      
      await _initFromStorage();
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (_mockUsers.containsKey(email)) {
        return Result.failure(const AuthException('Email already registered', code: 'EMAIL_EXISTS'));
      }
      
      if (password.length < 6) {
        return Result.failure(const ValidationException('Password must be at least 6 characters', code: 'PASSWORD_TOO_SHORT'));
      }
      
      _mockUsers[email] = password;
      
      final baseUser = await _loadUserFromAsset();
      final user = baseUser.copyWith(
        name: name,
        email: email,
        isOnboardingComplete: false,
      );
      
      _persistedProfiles[email] = user;
      await _saveToStorage();
      
      final updatedUser = user.copyWith(
        authToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        rememberMe: rememberMe,
      );
      
      _currentUser = updatedUser;
      _emitUser(_currentUser);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      
      if (rememberMe) {
        await prefs.setString(_authTokenKey, updatedUser.authToken!);
        await prefs.setString('user_email', email);
        await prefs.setString('user_password', password);
        await prefs.setString('user_name', name);
      }
      
      AppLogger.auth('Registration successful for email: $email');
      return Result.success(updatedUser);
    } catch (e) {
      AppLogger.auth('Registration failed', error: e);
      return Result.failure(
        DataException('Registration failed', originalError: e),
      );
    }
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    try {
      AppLogger.auth('Password reset request for email: $email');
      
      await _initFromStorage();
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!_mockUsers.containsKey(email)) {
        return Result.failure(const AuthException('Email not found', code: 'EMAIL_NOT_FOUND'));
      }
      
      AppLogger.auth('Password reset email sent to: $email');
      return Result.success(null);
    } catch (e) {
      AppLogger.auth('Password reset failed', error: e);
      return Result.failure(
        DataException('Password reset failed', originalError: e),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      AppLogger.auth('Logout attempt');
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      _currentUser = null;
      _emitUser(null);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_authTokenKey);
      
      AppLogger.auth('Logout successful');
      return Result.success(null);
    } catch (e) {
      AppLogger.auth('Logout failed', error: e);
      return Result.failure(
        DataException('Logout failed', originalError: e),
      );
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      if (_currentUser != null) {
        return Result.success(_currentUser);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          _currentUser = User.fromJson(userMap);
          _emitUser(_currentUser);
          return Result.success(_currentUser);
        } catch (e) {
          AppLogger.auth('Error parsing stored user', error: e);
        }
      }
      
      return Result.success(null);
    } catch (e) {
      AppLogger.auth('Failed to get current user', error: e);
      return Result.failure(
        CacheException('Failed to retrieve user session', originalError: e),
      );
    }
  }

  @override
  Future<Result<User>> updateUser(User user) async {
    try {
      AppLogger.auth('Updating user: ${user.email}');
      await _initFromStorage();
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentUser = user;
      _emitUser(_currentUser);
      
      _persistedProfiles[user.email] = user;
      await _saveToStorage();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      
      return Result.success(user);
    } catch (e) {
      AppLogger.auth('Update user failed', error: e);
      return Result.failure(DataException('Failed to update profile', originalError: e));
    }
  }

  @override
  Future<Result<void>> changePassword(String currentPassword, String newPassword) async {
    try {
      AppLogger.auth('Changing password');
      await _initFromStorage();
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_currentUser == null) return Result.failure(const AuthException('User not authenticated'));
      
      final email = _currentUser!.email;
      if (_mockUsers[email] != currentPassword) {
        return Result.failure(const AuthException('Incorrect current password'));
      }
      
      _mockUsers[email] = newPassword;
      await _saveToStorage();
      
      // Update StorageService for autofill if it was already stored
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('user_email') == email) {
        await prefs.setString('user_password', newPassword);
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(DataException('Failed to change password', originalError: e));
    }
  }

  @override
  Stream<User?> watchUser() async* {
    final current = await getCurrentUser();
    yield current.fold((user) => user, (error) => null);
    yield* _userController.stream;
  }

  Future<User> _loadUserFromAsset() async {
    final String jsonString = await rootBundle.loadString('assets/mock/user.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return User.fromJson(jsonMap);
  }
}