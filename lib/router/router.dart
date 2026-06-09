import 'package:crypto_king/presentation/pages/home/home_page.dart';
import 'package:crypto_king/presentation/pages/miner_detail/miner_detail_page.dart';
import 'package:crypto_king/presentation/pages/splash/splash_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'miner/:id',
            builder: (context, state) => MinerDetailPage(
              minerId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
}
