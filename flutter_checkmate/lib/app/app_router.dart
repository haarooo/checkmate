import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/auth_controller.dart';
import '../screens/create_room_screen.dart';
import '../screens/home_screen.dart';
import '../screens/join_room_screen.dart';
import '../screens/login_screen.dart';
import '../screens/member_status_screen.dart';
import '../screens/mission_rooms_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/point_history_screen.dart';
import '../screens/proof_feed_screen.dart';
import '../screens/proof_hub_screen.dart';
import '../screens/room_chat_screen.dart';
import '../screens/room_dashboard_screen.dart';
import '../screens/settlement_result_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/submit_proof_screen.dart';
import 'app_container.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authController,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/signup';
      final isInviteRoute = location.startsWith('/invite/');

      if (authController.status == AuthStatus.loading) {
        return location == '/splash' ? null : '/splash';
      }

      if (!authController.isAuthenticated) {
        return (isAuthRoute || isInviteRoute) ? null : '/login';
      }

      if (isAuthRoute || location == '/splash') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const AppContainer(child: SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AppContainer(child: LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const AppContainer(child: SignupScreen()),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AppContainer(child: HomeScreen()),
      ),
      GoRoute(
        path: '/proof',
        builder: (context, state) => const AppContainer(child: ProofHubScreen()),
      ),
      GoRoute(
        path: '/rooms',
        builder: (context, state) => const AppContainer(child: MissionRoomsScreen()),
      ),
      GoRoute(
        path: '/points',
        builder: (context, state) => const AppContainer(child: PointHistoryScreen()),
      ),
      GoRoute(
        path: '/rooms/create',
        builder: (context, state) => const AppContainer(child: CreateRoomScreen()),
      ),
      GoRoute(
        path: '/rooms/join',
        builder: (context, state) => const AppContainer(child: JoinRoomScreen()),
      ),
      GoRoute(
        path: '/invite/:inviteLinkToken',
        builder: (context, state) => AppContainer(
          child: JoinRoomScreen(
            initialInviteLinkToken: state.pathParameters['inviteLinkToken'],
          ),
        ),
      ),
      GoRoute(
        path: '/rooms/:roomId',
        builder: (context, state) {
          final roomId = _parseRoomId(state);
          if (roomId == null) return const AppContainer(child: _InvalidRoomIdScreen());
          return AppContainer(child: RoomDashboardScreen(roomId: roomId));
        },
      ),
      GoRoute(
        path: '/rooms/:roomId/members',
        builder: (context, state) {
          final roomId = _parseRoomId(state);
          if (roomId == null) return const AppContainer(child: _InvalidRoomIdScreen());
          return AppContainer(child: MemberStatusScreen(roomId: roomId));
        },
      ),
      GoRoute(
        path: '/rooms/:roomId/submit-proof',
        builder: (context, state) {
          final roomId = _parseRoomId(state);
          if (roomId == null) return const AppContainer(child: _InvalidRoomIdScreen());
          return AppContainer(child: SubmitProofScreen(roomId: roomId));
        },
      ),
      GoRoute(
        path: '/rooms/:roomId/proofs',
        builder: (context, state) {
          final roomId = _parseRoomId(state);
          if (roomId == null) return const AppContainer(child: _InvalidRoomIdScreen());
          return AppContainer(child: ProofFeedScreen(roomId: roomId));
        },
      ),
      GoRoute(
        path: '/rooms/:roomId/chat',
        builder: (context, state) {
          final roomId = _parseRoomId(state);
          if (roomId == null) return const AppContainer(child: _InvalidRoomIdScreen());
          return AppContainer(child: RoomChatScreen(roomId: roomId));
        },
      ),
      GoRoute(
        path: '/rooms/:roomId/settlement',
        builder: (context, state) {
          final roomId = _parseRoomId(state);
          if (roomId == null) return const AppContainer(child: _InvalidRoomIdScreen());
          return AppContainer(child: SettlementResultScreen(roomId: roomId));
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const AppContainer(child: NotificationScreen()),
      ),
      GoRoute(
        path: '/mypage',
        builder: (context, state) => const AppContainer(child: MyPageScreen()),
      ),
    ],
    errorBuilder: (context, state) => AppContainer(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 44, color: Color(0xFFEF4444)),
                const SizedBox(height: 12),
                const Text('페이지를 찾을 수 없습니다.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('홈으로 이동'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
});

int? _parseRoomId(GoRouterState state) {
  final value = state.pathParameters['roomId'];
  if (value == null) return null;
  return int.tryParse(value);
}

class _InvalidRoomIdScreen extends StatelessWidget {
  const _InvalidRoomIdScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 44, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              const Text('잘못된 방 주소입니다.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('홈으로 이동'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
