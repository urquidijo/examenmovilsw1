import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/tasks/screens/project_task_departments_screen.dart';
import '../../features/tasks/screens/department_tasks_screen.dart';
import '../../features/tasks/screens/task_detail_screen.dart';

final AuthService authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) async {
    final loggedIn = await authService.isAuthenticated();

    final isLogin = state.matchedLocation == '/login';
    final isRegister = state.matchedLocation == '/register';

    if (!loggedIn && !isLogin && !isRegister) {
      return '/login';
    }

    if (loggedIn && (isLogin || isRegister)) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'] ?? '';
        final projectName = state.extra as String? ?? 'Proyecto';

        return ProjectDetailScreen(
          projectId: projectId,
          projectName: projectName,
        );
      },
    ),
    GoRoute(
      path: '/projects/:projectId/tasks',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'] ?? '';
        final projectName = state.extra as String? ?? 'Proyecto';

        return ProjectTaskDepartmentsScreen(
          projectId: projectId,
          projectName: projectName,
        );
      },
    ),
    GoRoute(
      path: '/projects/:projectId/tasks/:taskId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'] ?? '';
        final taskId = state.pathParameters['taskId'] ?? '';

        return TaskDetailScreen(projectId: projectId, taskId: taskId);
      },
    ),
    GoRoute(
      path: '/projects/:projectId/tasks/departments/:departmentId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'] ?? '';
        final departmentId = state.pathParameters['departmentId'] ?? '';
        final departmentName = state.extra as String? ?? 'Departamento';

        return DepartmentTasksScreen(
          projectId: projectId,
          departmentId: departmentId,
          departmentName: departmentName,
        );
      },
    ),
  ],
);