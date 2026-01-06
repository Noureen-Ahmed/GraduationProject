import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_mode_provider.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_bottom_navigation.dart';

class DashboardShell extends ConsumerStatefulWidget {
  final Widget child;

  const DashboardShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  String _getCurrentRoute() {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return '/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = _getCurrentRoute();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main content
          Positioned.fill(child: widget.child),
          
          // Custom header - only show on home screen
          if (currentRoute == '/home')
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomHeader(),
            ),
          
          // Custom bottom navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomBottomNavigation(currentRoute: currentRoute),
          ),
          
          // Professor FAB
          if (ref.read(appModeControllerProvider.notifier).isProfessorMode())
            Positioned(
              bottom: 90, // Above bottom nav
              right: 24,
              child: GestureDetector(
                onTap: () => context.go('/add-content'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 37, 60, 235),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x662563EB),
                        blurRadius: 25,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}