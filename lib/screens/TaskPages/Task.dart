import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'AddTask.dart';
import 'Taskdetails.dart';
import '../../notification_service.dart';
import '../../providers/app_session_provider.dart';
import '../../storage_services.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  List<Map<String, dynamic>> tasks = [
    {
      "title": "Complete Data Structures Assignment",
      "course": "Computer Science",
      "priority": "high",
      "completed": false,
    },
    {
      "title": "Read Chapter 5 - Algorithms",
      "course": "Computer Science",
      "priority": "medium",
      "completed": false,
    },
    {
      "title": "Math Problem Set 7",
      "course": "Mathematics",
      "priority": "low",
      "completed": false,
    },
    {
      "title": "History Essay Draft",
      "course": "History",
      "priority": "medium",
      "completed": false,
    },
  ];

  void addTask(Map<String, dynamic> task) {
    setState(() {
      tasks.add({
        "title": task['title'],
        "course": task['course'] ?? "General",
        "priority": task['priority'] ?? "low",
        "completed": false,
        "description": task['description'] ?? "",
        "date": task['date'],
        "time": task['time'],
      });
    });
  }

  void removeTask(int index) {
    if (tasks[index]['notificationId'] != null) {
      NotificationService.cancelNotification(tasks[index]['notificationId']);
    }
    setState(() => tasks.removeAt(index));
  }

  void toggleComplete(int index) {
    setState(() => tasks[index]["completed"] = !tasks[index]["completed"]);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionControllerProvider);
    final isDoctor = session.maybeWhen(
      authenticated: (user) => StorageService.isDoctorEmail(user.email),
      orElse: () => false,
    );

    final String itemLabel = isDoctor ? 'Note' : 'Task';
    final String itemsLabel = isDoctor ? 'Notes' : 'Tasks';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.go('/home/$isDoctor');
          },
        ),
        title: Text(
          itemsLabel,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
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
                  '${tasks.where((t) => !t["completed"]).length}',
                  'Pending $itemsLabel',
                ),
                const SizedBox(width: 16),
                statBox(
                  '${tasks.where((t) => t["completed"]).length}',
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
                  MaterialPageRoute(builder: (context) => const AddTaskPage()),
                );
                if (result != null) {
                  addTask(result);
                }
              },
              child: Text(
                '+ Add New $itemLabel',
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Pending $itemsLabel',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...tasks
                .asMap()
                .entries
                .where((e) => !e.value["completed"])
                .map((e) => taskCard(e.key, e.value)),

            const SizedBox(height: 20),
            Text(
              'Completed $itemsLabel',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...tasks
                .asMap()
                .entries
                .where((e) => e.value["completed"])
                .map((e) => taskCard(e.key, e.value)),
            const SizedBox(height: 100), // Bottom padding for navigation bar
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
    switch (task['priority']?.toLowerCase()) {
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
            builder:
                (context) =>
                    TaskDetailsPage(task: task as Map<String, dynamic>),
          ),
        );
        if (updatedTask != null) {
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
              value: task["completed"],
              onChanged: (v) => toggleComplete(index),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task["title"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (task["course"] != null)
                    Text(
                      task["course"],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (task["description"] != null &&
                      task["description"].isNotEmpty)
                    Text(
                      task["description"],
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (task['date'] != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(task['date']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 10),
                      if (task['time'] != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task['time'].format(context),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 10),
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
