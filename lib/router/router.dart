import 'package:crypto_king/presentation/pages/main_shell.dart';
import 'package:crypto_king/presentation/pages/splash/splash_page.dart';
import 'package:crypto_king/presentation/pages/swap/swap_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShell(),
        routes: [
          GoRoute(path: 'swap', builder: (context, state) => const SwapPage()),
        ],
      ),
    ],
  );
}
