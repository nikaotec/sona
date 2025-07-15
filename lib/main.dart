import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sona/provider/audio_provider.dart';

// Providers
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:sona/provider/user_data_provider.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/provider/subscription_provider.dart';
import 'package:sona/provider/onboarding_provider.dart';
import 'package:sona/provider/video_ad_provider.dart';

// Screens
import 'package:sona/screen/category_screen.dart';
import 'package:sona/screen/category_music_list_screen.dart';
import 'package:sona/screen/enhanced_player_screen.dart';
import 'package:sona/screen/profile_screen.dart';
import 'package:sona/screen/enhanced_profile_screen.dart';
import 'package:sona/screen/paywall_screen.dart';
import 'package:sona/screen/onboarding_screen.dart';
import 'package:sona/screen/login_screen.dart';

// Services
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/audio_download_service.dart';
import 'package:sona/service/banner_ad_service.dart';
import 'package:sona/service/video_ad_service.dart';

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
        // Provider de áudio aprimorado
        ChangeNotifierProvider(create: (_) => EnhancedAudioProvider()),
        
        Provider<AdService>(create: (_) => AdService()),
        Provider<BannerAdService>(create: (_) => BannerAdService()),
        Provider<VideoAdService>(create: (_) => VideoAdService()),
        Provider<AudioDownloadService>(create: (_) => AudioDownloadService()),
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
        );
      },
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) => const EnhancedPlayerScreen(),
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

