import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'AddTask.dart';
import 'Taskdetails.dart';
import '../../notification_service.dart';
import '../../repositories/api_task_database.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final apiTasks = await ApiTaskDatabase.getAllTasks();
      setState(() {
        tasks = apiTasks.map((t) => {
          'id': t.id,
          'title': t.title,
          'course': t.course,
          'priority': t.priority,
          'completed': t.completed,
          'description': t.description ?? '',
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() => isLoading = false);
    }
  }

  void addTask(Map<String, dynamic> taskData) async {
    // Generate a temporary ID for optimistic UI
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final newTaskMap = {
      'id': tempId,
      'title': taskData['title'] ?? '',
      'course': taskData['course'] ?? 'General',
      'priority': taskData['priority'] ?? 'low',
      'completed': false,
      'description': taskData['description'] ?? '',
    };

    // Optimistically update list
    setState(() {
      tasks.insert(0, newTaskMap);
    });

    try {
      final savedTask = await ApiTaskDatabase.addTask(
        title: taskData['title'] ?? '',
        course: taskData['course'] ?? 'General',
        priority: taskData['priority'] ?? 'low',
        description: taskData['description'],
      );

      if (savedTask != null) {
        // Replace temp task with real task from server
        setState(() {
          final index = tasks.indexWhere((t) => t['id'] == tempId);
          if (index != -1) {
            tasks[index] = {
              'id': savedTask.id,
              'title': savedTask.title,
              'course': savedTask.course,
              'priority': savedTask.priority,
              'completed': savedTask.completed,
              'description': savedTask.description ?? '',
            };
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task saved to cloud'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        throw Exception('Failed to save task');
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        tasks.removeWhere((t) => t['id'] == tempId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save task. Please check connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void removeTask(int index) async {
    final task = tasks[index];
    final taskId = task['id']?.toString();
    
    // Save for potential rollback
    final removedItem = tasks[index];
    final removedIndex = index;

    // Optimistically remove
    setState(() {
      tasks.removeAt(index);
    });

    if (task['notificationId'] != null) {
      NotificationService.cancelNotification(task['notificationId']);
    }
    
    if (taskId != null && !taskId.startsWith('temp_')) {
      try {
        final success = await ApiTaskDatabase.deleteTask(taskId);
        if (!success) throw Exception();
      } catch (e) {
        // Rollback
        setState(() {
          tasks.insert(removedIndex, removedItem);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete task')),
          );
        }
      }
    }
  }

  void toggleComplete(int index) async {
    final task = tasks[index];
    final taskId = task['id']?.toString();
    if (taskId == null || taskId.startsWith('temp_')) return;
    
    final oldStatus = task['completed'];

    // Optimistically toggle
    setState(() {
      tasks[index]['completed'] = !oldStatus;
    });

    try {
      final success = await ApiTaskDatabase.toggleComplete(taskId);
      if (!success) throw Exception();
    } catch (e) {
      // Rollback
      setState(() {
        tasks[index]['completed'] = oldStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update task')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Tasks',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() => isLoading = true);
              _loadTasks();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          statBox(
                            '${tasks.where((t) => !(t['completed'] ?? false)).length}',
                            'Pending Tasks',
                          ),
                          const SizedBox(width: 16),
                          statBox(
                            '${tasks.where((t) => t['completed'] ?? false).length}',
                            'Completed',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddTaskPage()),
                          );
                          if (result != null) {
                            addTask(result);
                          }
                        },
                        child: const Text(
                          '+ Add New Task',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Pending Tasks',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...tasks
                          .asMap()
                          .entries
                          .where((e) => !(e.value['completed'] ?? false))
                          .map((e) => taskCard(e.key, e.value)),

                      const SizedBox(height: 20),
                      const Text(
                        'Completed Tasks',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...tasks
                          .asMap()
                          .entries
                          .where((e) => e.value['completed'] ?? false)
                          .map((e) => taskCard(e.key, e.value)),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget taskCard(int index, Map task) {
    Color priorityColor;
    switch ((task['priority'] ?? '').toString().toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () async {
        final updatedTask = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TaskDetailsPage(task: Map<String, dynamic>.from(task)),
          ),
        );
        if (updatedTask != null) {
          final taskId = tasks[index]['id']?.toString();
          if (taskId != null) {
            await ApiTaskDatabase.updateTask(taskId, updatedTask);
          }
          setState(() => tasks[index] = {...tasks[index], ...updatedTask});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          children: [
            Checkbox(
              value: task['completed'] ?? false,
              onChanged: (v) => toggleComplete(index),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: (task['completed'] ?? false)
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (task['course'] != null)
                    Text(
                      task['course'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (task['description'] != null &&
                      task['description'].toString().isNotEmpty)
                    Text(
                      task['description'],
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  const SizedBox(height: 4),
                  if (task['priority'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task['priority'],
                        style: TextStyle(
                          fontSize: 12,
                          color: priorityColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => removeTask(index),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
