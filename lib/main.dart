


import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import AdMob
import 'package:sona/provider/audio_provider.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/provider/user_data_provider.dart';
import 'package:sona/screen/category_screen.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/audio_download_service.dart'; // Import AudioDownloadService
import 'package:sona/screen/login_screen.dart';
import 'package:sona/screen/onbloarding_screen.dart';
import 'package:sona/screen/paywall_screen.dart';
import 'package:sona/screen/player_screen.dart';
import 'package:sona/screen/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize(); // Inicializa o AdMob
  runApp(const SonaApp());
}

class SonaApp extends StatelessWidget {
  const SonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final _router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/categories', builder: (_, __) => const CategoryScreen()),
        GoRoute(path: '/player', builder: (_, __) => const PlayerScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
      ],
    );

    return MultiProvider(
      providers: [
        // AdService como Provider simples, pois não é ChangeNotifier
        Provider<AdService>(create: (_) => AdService()),
        Provider<AudioDownloadService>(create: (_) => AudioDownloadService()),
        ChangeNotifierProvider(create: (_) => PaywallProvider()..loadData()), // Carrega dados ao iniciar
        ChangeNotifierProvider(create: (_) => UserDataProvider()..loadFavorites()), // Assumindo que tem um método para carregar dados
        // AudioProvider pode depender de AdService, então é bom registrá-lo depois ou injetar AdService
        ChangeNotifierProxyProvider<AdService, AudioProvider>(
          create: (context) => AudioProvider(),
          update: (context, adService, audioProvider) {
            audioProvider ??= AudioProvider();
            audioProvider.setAdService(adService); // Injeta AdService
            return audioProvider;
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Sona',
        theme: ThemeData.dark(),
        routerConfig: _router,
      ),
    );
  }
}

