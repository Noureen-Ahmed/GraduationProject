import '../models/task.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<List<Task>> getPendingTasks();
  Future<List<Task>> getCompletedTasks();
  Future<Task?> getTaskById(String id);
  Future<void> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> toggleTaskStatus(String id);
  Stream<List<Task>> watchTasks();
}

class MockTaskRepository implements TaskRepository {
  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Complete Data Structures Assignment',
      subject: 'Computer Science',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      status: TaskStatus.pending,
      priority: TaskPriority.high,
      description: 'Complete the programming assignment on binary trees and graphs',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Task(
      id: '2',
      title: 'Read Chapter 5 - Algorithms',
      subject: 'Computer Science',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      status: TaskStatus.pending,
      priority: TaskPriority.medium,
      description: 'Read and understand sorting algorithms',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Task(
      id: '3',
      title: 'Physics Lab Report',
      subject: 'Physics',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: TaskStatus.completed,
      priority: TaskPriority.medium,
      description: 'Submit lab report on wave mechanics',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
    ),
    Task(
      id: '4',
      title: 'Math Problem Set 7',
      subject: 'Mathematics',
      dueDate: DateTime.now().add(const Duration(days: 4)),
      status: TaskStatus.pending,
      priority: TaskPriority.low,
      description: 'Complete calculus problem set',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Task(
      id: '5',
      title: 'History Essay Draft',
      subject: 'History',
      dueDate: DateTime.now().add(const Duration(days: 6)),
      status: TaskStatus.pending,
      priority: TaskPriority.medium,
      description: 'Write first draft of history essay',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<Task>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_tasks);
  }

  @override
  Future<List<Task>> getPendingTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tasks.where((task) => task.status == TaskStatus.pending).toList();
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tasks.where((task) => task.status == TaskStatus.completed).toList();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tasks.add(task);
  }

  @override
  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tasks.removeWhere((task) => task.id == id);
  }

  @override
  Future<void> toggleTaskStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(
        status: task.status == TaskStatus.pending 
            ? TaskStatus.completed 
            : TaskStatus.pending,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Stream<List<Task>> watchTasks() {
    return Stream.value(List.from(_tasks));
  }
}