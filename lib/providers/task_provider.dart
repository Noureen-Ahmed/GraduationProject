import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return MockTaskRepository();
});

final tasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTasks();
});

final pendingTasksProvider = FutureProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).getPendingTasks();
});

final completedTasksProvider = FutureProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).getCompletedTasks();
});

final taskControllerProvider = StateNotifierProvider<TaskController, AsyncValue<void>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskController(repository);
});

class TaskController extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repository;

  TaskController(this._repository) : super(const AsyncValue.data(null));

  Future<void> addTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addTask(task);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTask(task);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTask(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleTaskStatus(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.toggleTaskStatus(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addTask(task);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final taskFilterProvider = StateProvider<TaskFilter>((ref) {
  return TaskFilter();
});

class TaskFilter {
  final TaskStatus? status;
  final TaskPriority? priority;
  final DateTime? dueDate;
  final String searchTerm;

  TaskFilter({
    this.status,
    this.priority,
    this.dueDate,
    this.searchTerm = '',
  });

  TaskFilter copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    String? searchTerm,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}