import 'package:flutter/foundation.dart';

class AdConfig {
  // IDs de teste do Google AdMob
  static const String testRewardedAdUnitIdAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String testRewardedAdUnitIdIOS = 'ca-app-pub-3940256099942544/1712485313';
  static const String testBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const String testBannerAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String testInterstitialAdUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialAdUnitIdIOS = 'ca-app-pub-3940256099942544/4411468910';

  // IDs de produção (substitua pelos seus IDs reais quando publicar)
  static const String prodRewardedAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String prodRewardedAdUnitIdIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String prodBannerAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String prodBannerAdUnitIdIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String prodInterstitialAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String prodInterstitialAdUnitIdIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Flag para determinar se está em modo de teste
  static const bool isTestMode = true; // Mude para false em produção

  // Getters para IDs de anúncios recompensados
  static String get rewardedAdUnitId {
    if (isTestMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? testRewardedAdUnitIdAndroid
          : testRewardedAdUnitIdIOS;
    } else {
      return defaultTargetPlatform == TargetPlatform.android
          ? prodRewardedAdUnitIdAndroid
          : prodRewardedAdUnitIdIOS;
    }
  }

  // Getters para IDs de banners
  static String get bannerAdUnitId {
    if (isTestMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? testBannerAdUnitIdAndroid
          : testBannerAdUnitIdIOS;
    } else {
      return defaultTargetPlatform == TargetPlatform.android
          ? prodBannerAdUnitIdAndroid
          : prodBannerAdUnitIdIOS;
    }
  }

  // Getters para IDs de intersticiais
  static String get interstitialAdUnitId {
    if (isTestMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? testInterstitialAdUnitIdAndroid
          : testInterstitialAdUnitIdIOS;
    } else {
      return defaultTargetPlatform == TargetPlatform.android
          ? prodInterstitialAdUnitIdAndroid
          : prodInterstitialAdUnitIdIOS;
    }
  }

  // Configurações de frequência de anúncios
  static const int maxDailyPlaysWithoutAds = 3;
  static const int bannerFrequency = 5; // Mostrar banner a cada 5 itens na lista
  static const Duration adLoadTimeout = Duration(seconds: 10);
}

