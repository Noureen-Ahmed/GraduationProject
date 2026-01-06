import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigation extends StatelessWidget {
  final String currentRoute;
  
  const CustomBottomNavigation({
    super.key,
    required this.currentRoute,
  });

  static const List<Map<String, dynamic>> tabs = [
    {
      'label': 'Home',
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
      'route': '/home',
    },
    {
      'label': 'Tasks',
      'icon': Icons.task_outlined,
      'activeIcon': Icons.task,
      'route': '/tasks',
    },
    {
      'label': 'Schedule',
      'icon': Icons.schedule_outlined,
      'activeIcon': Icons.schedule,
      'route': '/schedule',
    },
    {
      'label': 'Navigate',
      'icon': Icons.explore_outlined,
      'activeIcon': Icons.explore,
      'route': '/navigate',
    },
    {
      'label': 'Profile',
      'icon': Icons.person_outlined,
      'activeIcon': Icons.person,
      'route': '/profile',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          final isActive = currentRoute == tab['route'];
          
          return GestureDetector(
            onTap: () => context.go(tab['route']),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? tab['activeIcon'] : tab['icon'],
                    size: 24,
                    color: isActive ? const Color(0xFF4338CA) : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? const Color(0xFF4338CA) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}