import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'app_session_provider.dart';

/// Provides the current user from the session state
/// This watches the appSessionControllerProvider for immediate updates
final currentUserProvider = Provider<AsyncValue<User?>>((ref) {
  final sessionState = ref.watch(appSessionControllerProvider);
  return sessionState.maybeWhen(
    authenticated: (user) => AsyncValue.data(user),
    loading: () => const AsyncValue.loading(),
    orElse: () => const AsyncValue.data(null),
  );
});

final appModeControllerProvider = StateNotifierProvider<AppModeController, AppMode>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AppModeController(repository);
});

class AppModeController extends StateNotifier<AppMode> {
  final AuthRepository _repository;

  AppModeController(this._repository) : super(AppMode.student) {
    _loadCurrentMode();
  }

  Future<void> _loadCurrentMode() async {
    final result = await _repository.getCurrentUser();
    final user = result.fold((user) => user, (error) => null);
    if (user != null) {
      state = user.mode;
    }
  }

  Future<void> switchMode(AppMode mode) async {
    state = mode;
    final result = await _repository.getCurrentUser();
    final user = result.fold((user) => user, (error) => null);
    if (user != null) {
      await _repository.updateUser(user.copyWith(mode: mode));
    }
  }

  bool isProfessorMode() {
    return state == AppMode.professor;
  }

  bool isStudentMode() {
    return state == AppMode.student;
  }
}