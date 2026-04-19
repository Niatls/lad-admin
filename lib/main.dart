import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lad_admin/screens/login_screen.dart';
import 'package:lad_admin/screens/home_screen.dart';
import 'package:lad_admin/screens/applications_screen.dart';
import 'package:lad_admin/screens/application_detail_screen.dart';
import 'package:lad_admin/screens/chat_list_screen.dart';
import 'package:lad_admin/screens/chat_room_screen.dart';
import 'package:lad_admin/widgets/navigation_shell.dart';
import 'package:lad_admin/core/auth_service.dart';

void main() {
  runApp(const ProviderScope(child: LadAdminApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final isAuthenticated = await AuthService.isAuthenticated();
    final isLoggingIn = state.matchedLocation == '/login';

    if (!isAuthenticated && !isLoggingIn) return '/login';
    if (isAuthenticated && isLoggingIn) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Use ShellRoute for persistent navigation
    ShellRoute(
      builder: (context, state, child) => NavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/applications',
          builder: (context, state) => const ApplicationsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return ApplicationDetailScreen(id: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const ChatListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return ChatRoomScreen(sessionId: id);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

class LadAdminApp extends StatelessWidget {
  const LadAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lad Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6741),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
