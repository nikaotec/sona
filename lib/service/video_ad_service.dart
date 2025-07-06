import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sona/utils/ad_config.dart';

class VideoAdService {
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isRewardedInterstitialAdReady = false;

  bool get isRewardedInterstitialAdReady => _isRewardedInterstitialAdReady;

  void loadRewardedInterstitialAd() {
    if (_isRewardedInterstitialAdReady) return;

    RewardedInterstitialAd.load(
      adUnitId: AdConfig.rewardedAdUnitId, // Usando o mesmo ID por enquanto
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialAdReady = true;
          // debugPrint('✅ RewardedInterstitialAd (Video) carregado.'); // Removido
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedInterstitialAd = null;
          _isRewardedInterstitialAdReady = false;
          // debugPrint('❌ Erro ao carregar RewardedInterstitialAd (Video): $error'); // Removido
        },
      ),
    );
  }

  void showVideoAd({
    required VoidCallback onAdDismissed,
    required Function(String) onAdFailedToLoadOrShow,
    required VoidCallback onUserEarnedRewardCallback,
  }) {
    if (_rewardedInterstitialAd != null && _isRewardedInterstitialAdReady) {
      _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) =>
            // debugPrint('📺 Anúncio em vídeo mostrado: $ad'), // Removido
            null,
        onAdDismissedFullScreenContent: (ad) {
          // debugPrint('🔙 Anúncio em vídeo fechado: $ad'); // Removido
          ad.dispose();
          _isRewardedInterstitialAdReady = false;
          onAdDismissed();
          loadRewardedInterstitialAd(); // Pré-carrega o próximo anúncio
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          // debugPrint('❌ Falha ao exibir anúncio em vídeo: $error'); // Removido
          ad.dispose();
          _isRewardedInterstitialAdReady = false;
          onAdFailedToLoadOrShow(error.message);
          loadRewardedInterstitialAd(); // Tenta carregar outro
        },
      );

      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          // debugPrint('🎉 Usuário ganhou recompensa do vídeo: ${reward.amount} ${reward.type}'); // Removido
          onUserEarnedRewardCallback();
        },
      );

      _rewardedInterstitialAd = null; // Previne múltiplos usos
    } else {
      // debugPrint('⚠️ Anúncio em vídeo não está pronto'); // Removido
      onAdFailedToLoadOrShow('Anúncio em vídeo não está pronto.');
      loadRewardedInterstitialAd();
    }
  }

  void dispose() {
    _rewardedInterstitialAd?.dispose();
  }
}


