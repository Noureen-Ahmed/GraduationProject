import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/result.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/mock/mock_auth_repository.dart';

part 'app_session_provider.freezed.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final appSessionControllerProvider = StateNotifierProvider<AppSessionController, AppSessionState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AppSessionController(authRepository);
});

final authStateProvider = Provider<AuthState>((ref) {
  final sessionState = ref.watch(appSessionControllerProvider);
  final user = sessionState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
  if (user == null) {
    return const AuthState.unauthenticated();
  } else if (!user.isOnboardingComplete) {
    return AuthState.onboardingRequired(user);
  } else {
    return AuthState.authenticated(user);
  }
});

class AppSessionController extends StateNotifier<AppSessionState> {
  final AuthRepository _authRepository;
  
  AppSessionController(this._authRepository) : super(const AppSessionState.initial()) {
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      state = const AppSessionState.loading();
      
      final result = await _authRepository.getCurrentUser();
      final user = result.fold(
        (user) => user,
        (error) {
          AppLogger.auth('Failed to initialize session', error: error);
          return null;
        },
      );
      
      if (user != null) {
        state = AppSessionState.authenticated(user);
      } else {
        state = const AppSessionState.unauthenticated();
      }
    } catch (e) {
      AppLogger.auth('Session initialization error', error: e);
      state = const AppSessionState.unauthenticated();
    }
  }

  Future<Result<User>> login(String email, String password, {bool rememberMe = false}) async {
    try {
      state = const AppSessionState.loading();
      
      final result = await _authRepository.login(email, password, rememberMe: rememberMe);
      
      return result.fold(
        (user) {
          state = AppSessionState.authenticated(user);
          return Result.success(user);
        },
        (error) {
          state = AppSessionState.error(error.message);
          return Result.failure(error);
        },
      );
    } catch (e) {
      final error = DataException('Login failed', originalError: e);
      state = AppSessionState.error(error.message);
      return Result.failure(error);
    }
  }

  Future<Result<User>> register(String name, String email, String password, {bool rememberMe = false}) async {
    try {
      state = const AppSessionState.loading();
      
      final result = await _authRepository.register(name, email, password, rememberMe: rememberMe);
      
      return result.fold(
        (user) {
          state = AppSessionState.authenticated(user);
          return Result.success(user);
        },
        (error) {
          state = AppSessionState.error(error.message);
          return Result.failure(error);
        },
      );
    } catch (e) {
      final error = DataException('Registration failed', originalError: e);
      state = AppSessionState.error(error.message);
      return Result.failure(error);
    }
  }

  Future<Result<void>> forgotPassword(String email) async {
    try {
      final result = await _authRepository.forgotPassword(email);
      return result;
    } catch (e) {
      return Result.failure(
        DataException('Password reset failed', originalError: e),
      );
    }
  }

  Future<Result<void>> logout() async {
    try {
      state = const AppSessionState.loading();
      
      final result = await _authRepository.logout();
      
      return result.fold(
        (_) {
          state = const AppSessionState.unauthenticated();
          return Result.success(null);
        },
        (error) {
          state = AppSessionState.error(error.message);
          return Result.failure(error);
        },
      );
    } catch (e) {
      final error = DataException('Logout failed', originalError: e);
      state = AppSessionState.error(error.message);
      return Result.failure(error);
    }
  }

  Future<void> completeOnboarding(List<String> selectedCourseIds) async {
    try {
      final currentUser = state.maybeWhen(
        authenticated: (user) => user,
        orElse: () => null,
      );
      
      if (currentUser == null) return;
      
      final updatedUser = currentUser.copyWith(
        enrolledCourses: selectedCourseIds,
        isOnboardingComplete: true,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(updatedUser.toJson()));
      
      state = AppSessionState.authenticated(updatedUser);
      
      AppLogger.auth('Onboarding completed for user: ${currentUser.email}');
    } catch (e) {
      AppLogger.auth('Failed to complete onboarding', error: e);
    }
  }

  Future<Result<User>> updateUser(User user) async {
    try {
      final result = await _authRepository.updateUser(user);
      return result.fold(
        (updatedUser) {
          state = AppSessionState.authenticated(updatedUser);
          return Result.success(updatedUser);
        },
        (error) => Result.failure(error),
      );
    } catch (e) {
      return Result.failure(DataException('Update failed', originalError: e));
    }
  }

  Future<Result<void>> changePassword(String currentPassword, String newPassword) async {
    try {
      return await _authRepository.changePassword(currentPassword, newPassword);
    } catch (e) {
      return Result.failure(DataException('Password change failed', originalError: e));
    }
  }
}

@freezed
class AppSessionState with _$AppSessionState {
  const factory AppSessionState.initial() = _Initial;
  const factory AppSessionState.loading() = _Loading;
  const factory AppSessionState.authenticated(User user) = _Authenticated;
  const factory AppSessionState.unauthenticated() = _Unauthenticated;
  const factory AppSessionState.error(String message) = _Error;
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = _AuthUnauthenticated;
  const factory AuthState.onboardingRequired(User user) = _AuthOnboardingRequired;
  const factory AuthState.authenticated(User user) = _AuthAuthenticated;
}