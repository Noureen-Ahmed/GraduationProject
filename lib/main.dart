import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/app_session_provider.dart';
import 'screens/dashboard_shell.dart';
import 'screens/home_screen.dart';
import 'screens/TaskPages/Task.dart';
import 'screens/schedule_screen.dart';
import 'screens/navigate_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/add_content_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/course_selection_screen.dart';
import 'screens/auth/verification_page.dart';
import 'storage_services.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Services
  await StorageService.init();
  await NotificationService.init();
  await NotificationService.requestPermissions();

  runApp(const ProviderScope(child: StudentDashboardApp()));
}

class StudentDashboardApp extends ConsumerStatefulWidget {
  const StudentDashboardApp({super.key});

  @override
  ConsumerState<StudentDashboardApp> createState() =>
      _StudentDashboardAppState();
}

class _StudentDashboardAppState extends ConsumerState<StudentDashboardApp> {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      navigatorKey: _navigatorKey,
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/verification',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>?;
            return VerificationPage(
              email: extra?['email'] ?? '',
              password: extra?['password'],
            );
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/course-selection',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>?;
            return SelectCoursePage(
              email: extra?['email'] ?? '',
              password: extra?['password'],
            );
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            return DashboardShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TasksPage(),
            ),
            GoRoute(
              path: '/schedule',
              builder: (context, state) => const ScheduleScreen(),
            ),
            GoRoute(
              path: '/navigate',
              builder: (context, state) => const NavigateScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/course/:courseId',
              builder: (context, state) {
                final courseId = state.pathParameters['courseId']!;
                return CourseDetailScreen(courseId: courseId);
              },
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/add-content',
              builder: (context, state) => const AddContentScreen(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Redirection Logic
    void handleRedirection() {
      final currentLocation = _router.routerDelegate.currentConfiguration.uri.path;
      final isAuthRoute = currentLocation.startsWith('/login') ||
          currentLocation.startsWith('/register') ||
          currentLocation.startsWith('/forgot-password') ||
          currentLocation.startsWith('/verification'); 
      final isOnboardingRoute = currentLocation == '/course-selection';

  authState.when(
    unauthenticated: () {
      if (!isAuthRoute && !isOnboardingRoute) _router.go('/login');
    },
    onboardingRequired: (user) {
      if (!isOnboardingRoute) _router.go('/course-selection');
    },
    authenticated: (user) {
      if (isAuthRoute || isOnboardingRoute) {
        _router.go('/home');
      }
    },
  );

    }

    // Checking on build and listener
    WidgetsBinding.instance.addPostFrameCallback((_) => handleRedirection());
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (previous != next) handleRedirection();
    });

    return MaterialApp.router(
      title: 'Student Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF6366F1),
          unselectedItemColor: Colors.grey,
        ),
      ),
      routerConfig: _router,
    );
  }
}
