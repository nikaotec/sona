import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/provider/subscription_provider.dart';
import 'package:sona/provider/video_ad_provider.dart';
import 'package:sona/provider/user_data_provider.dart';
import 'package:sona/provider/onboarding_provider.dart';
import 'package:sona/screen/category_music_list_screen.dart';
import 'package:sona/screen/category_screen.dart';
import 'package:sona/screen/onboarding_screen.dart';
import 'package:sona/screen/player_screen.dart';
import 'package:sona/screen/profile_screen.dart';
import 'package:sona/screen/splash)screen.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/banner_ad_service.dart';
import 'package:sona/service/video_ad_service.dart';
import 'package:sona/service/audio_download_service.dart';
import 'package:sona/screen/login_screen.dart';
import 'package:sona/screen/paywall_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();
  MobileAds.instance.initialize(); // Inicializa o AdMob
  runApp(const SonaApp());
  FlutterNativeSplash.remove();
}

class SonaApp extends StatelessWidget {
  const SonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, state) {
            final editParam = state.uri.queryParameters['edit'];
            final isEditMode = editParam == 'true';
            return OnboardingScreen(isEditMode: isEditMode);
          },
        ),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: '/categories',
          builder: (_, __) => const CategoryScreen(),
        ),
        GoRoute(
          path: '/category-music-list',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CategoryMusicListScreen(
              // Versão corrigida
              categoryName: extra?['categoryName'] ?? 'Categoria',
              audios: extra?['audios'] ?? [],
              heroTag: extra?['heroTag'],
            );
          },
        ),
        GoRoute(
          path: '/player',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PlayerScreen(
              // Versão corrigida
              heroTag: extra?['heroTag'],
            );
          },
        ),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
      ],
      // Configuração de redirecionamento se necessário
      redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final onboardingCompleted =
            prefs.getBool("onboarding_completed") ?? false;

        final isEditMode =
            state.extra is Map && (state.extra as Map)['isEditMode'] == true;

        if (state.fullPath == '/onboarding' && isEditMode) {
          return '{/onboarding?isEditMode=$isEditMode}';
        } else if (onboardingCompleted &&
            state.fullPath == '/onboarding' &&
            !isEditMode) {
          return "/categories";
        } else {
          return null;
        }
      },
    );

    return MultiProvider(
      providers: [
        Provider<AdService>(create: (_) => AdService()),
        Provider<BannerAdService>(create: (_) => BannerAdService()),
        Provider<VideoAdService>(create: (_) => VideoAdService()),
        Provider<AudioDownloadService>(create: (_) => AudioDownloadService()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProxyProvider<SubscriptionProvider, VideoAdProvider>(
          create:
              (context) => VideoAdProvider(
                Provider.of<SubscriptionProvider>(context, listen: false),
              ),
          update: (context, subscriptionProvider, videoAdProvider) {
            return videoAdProvider ?? VideoAdProvider(subscriptionProvider);
          },
        ),
        ChangeNotifierProxyProvider<SubscriptionProvider, PaywallProvider>(
          create: (context) => PaywallProvider(),
          update: (context, subscriptionProvider, paywallProvider) {
            paywallProvider ??= PaywallProvider();
            paywallProvider
                .loadData(); // Garante que os dados são carregados após a inicialização
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
      child: MaterialApp.router(
        title: 'Sona',
        theme: ThemeData.dark().copyWith(
          // Personalização do tema se necessário
          primaryColor: const Color(0xFF6B73FF),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6B73FF),
            secondary: Color(0xFF9644FF),
          ),
          // Configurações de transição de página
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
