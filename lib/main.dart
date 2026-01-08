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
import 'screens/dr_course_details.dart';
import 'screens/add_content_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/course_selection_screen.dart';
import 'screens/auth/verification_page.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'storage_services.dart';
import 'notification_service.dart';
import 'screens/student_guide/guide_selection_screen.dart';
import 'screens/student_guide/explain_screen.dart';
import 'screens/student_guide/explain_program.dart';
import 'screens/guest/guest_dashboard_shell.dart';
import 'screens/guest/guest_home_screen.dart';
import 'screens/courses_screen.dart';

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
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
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
            return GuestDashboardShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/guest/home',
              builder: (context, state) => const GuestHomeScreen(),
            ),
            GoRoute(
              path: '/guest/ar',
              builder: (context, state) => const NavigateScreen(isGuest: true),
            ),
             GoRoute(
              path: '/guest/credit',
              builder: (context, state) => const ExplainScreen(),
            ),
             GoRoute(
              path: '/guest/departments',
              builder: (context, state) => const ExplainProgram(),
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) {
            return DashboardShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/home/:isDoctor',
              builder: (context, state) { 
                // final isDoctor = false;
                final isDoctor = state.pathParameters['isDoctor'] == 'true';
                return HomeScreen(isDoctor: isDoctor);
              },
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
              path: '/courses',
              builder: (context, state) => const CoursesScreen(),
            ),
            GoRoute(
              path: '/dr-course/:courseId',
              builder: (context, state) {
                final courseId = state.pathParameters['courseId']!;
                return DrCourseDetails(courseId: courseId);
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
          currentLocation.startsWith('/verification') ||
          currentLocation.startsWith('/splash') ||
          currentLocation.startsWith('/welcome') ||
          currentLocation.startsWith('/guest/'); 
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
        final isDoctor = StorageService.isDoctorEmail(user.email);
        _router.go('/home/$isDoctor');
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
