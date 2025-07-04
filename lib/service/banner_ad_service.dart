import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sona/utils/ad_config.dart';

class BannerAdService {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdReady => _isBannerAdReady;

  void loadBannerAd() {
    if (_isBannerAdReady) return;

    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          debugPrint('✅ BannerAd carregado.');
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdReady = false;
          ad.dispose();
          debugPrint('❌ Erro ao carregar BannerAd: $error');
        },
        onAdOpened: (ad) => debugPrint('📱 BannerAd aberto.'),
        onAdClosed: (ad) => debugPrint('🔙 BannerAd fechado.'),
      ),
    );

    _bannerAd!.load();
  }

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
  }
}

