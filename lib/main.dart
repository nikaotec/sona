import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Providers
import 'package:sona/provider/audio_provider.dart';
import 'package:sona/provider/mix_manager_provider.dart';
import 'package:sona/provider/user_data_provider.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/provider/subscription_provider.dart';
import 'package:sona/provider/onboarding_provider.dart';
import 'package:sona/provider/video_ad_provider.dart';

// Screens
import 'package:sona/screen/category_screen.dart';
import 'package:sona/screen/category_music_list_screen.dart';
import 'package:sona/screen/player_screen.dart';
import 'package:sona/screen/mix_edit_screen.dart';
import 'package:sona/screen/profile_screen.dart';
import 'package:sona/screen/enhanced_profile_screen.dart';
import 'package:sona/screen/paywall_screen.dart';
import 'package:sona/screen/onboarding_screen.dart';
import 'package:sona/screen/login_screen.dart';

// Services
import 'package:sona/service/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Inicializar Google Mobile Ads
  await MobileAds.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider de anúncios
        Provider(create: (_) => AdService()),
        // Provider de áudio principal
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        
        // Provider de gerenciamento de mixes
        ChangeNotifierProvider(create: (_) => MixManagerProvider()),
        
        // Outros providers
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => PaywallProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
         ChangeNotifierProxyProvider<SubscriptionProvider, VideoAdProvider>(
          create: (context) =>
              VideoAdProvider(Provider.of<SubscriptionProvider>(context, listen: false)),
          update: (context, subscriptionProvider, videoAdProvider) {
            return videoAdProvider ?? VideoAdProvider(subscriptionProvider);
          },
        ),
        ChangeNotifierProxyProvider<SubscriptionProvider, PaywallProvider>(
          create: (context) => PaywallProvider(),
          update: (context, subscriptionProvider, paywallProvider) {
            paywallProvider ??= PaywallProvider();
            paywallProvider.loadData();
            return paywallProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProxyProvider<AdService, AudioProvider>(
          create: (context) => AudioProvider(),
          update: (context, adService, audioProvider) {
            audioProvider ??= AudioProvider();
            audioProvider.setAdService(adService);
            return audioProvider;
          },
        ),
        
        // Provider de anúncios
        Provider(create: (_) => AdService()),
      ],
      child: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          return MaterialApp.router(
            title: 'Sona - MindWave',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/categories',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoryScreen(),
    ),
    GoRoute(
      path: '/category-music-list',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CategoryMusicListScreen(
          categoryName: extra?['categoryName'] ?? 'Categoria',
          audios: extra?['audios'] ?? [],
          heroTag: extra?['heroTag'],
          mixId: extra?['mixId'], // Para adicionar músicas a um mix específico
        );
      },
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PlayerScreen(
          heroTag: extra?['heroTag'],
        );
      },
    ),
    GoRoute(
      path: '/mix_edit/:mixId',
      builder: (context, state) {
        final mixId = state.pathParameters['mixId']!;
        return MixEditScreen(mixId: mixId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/enhanced-profile',
      builder: (context, state) => const EnhancedProfileScreen(),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
    ),
  ],
);

