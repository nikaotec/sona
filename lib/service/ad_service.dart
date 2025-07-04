import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  final String _rewardedAdUnitId = defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-3940256099942544/5224354917' // Teste Android
      : 'ca-app-pub-3940256099942544/1712485313'; // Teste iOS

  void loadRewardedAd() {
    if (_isRewardedAdReady) return;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          debugPrint('✅ RewardedAd carregado.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isRewardedAdReady = false;
          debugPrint('❌ Erro ao carregar RewardedAd: $error');
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onAdDismissed,
    required Function(String) onAdFailedToLoadOrShow,
    required VoidCallback onUserEarnedRewardCallback,
  }) {
    if (_rewardedAd != null && _isRewardedAdReady) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) =>
            debugPrint('📺 Anúncio mostrado: $ad'),
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('🔙 Anúncio fechado: $ad');
          ad.dispose();
          _isRewardedAdReady = false;
          onAdDismissed();
          loadRewardedAd(); // Pré-carrega o próximo anúncio
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('❌ Falha ao exibir anúncio: $error');
          ad.dispose();
          _isRewardedAdReady = false;
          onAdFailedToLoadOrShow(error.message);
          loadRewardedAd(); // Tenta carregar outro
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('🎉 Usuário ganhou recompensa: ${reward.amount} ${reward.type}');
          onUserEarnedRewardCallback();
        },
      );

      _rewardedAd = null; // Previne múltiplos usos
    } else {
      debugPrint('⚠️ Anúncio não está pronto');
      onAdFailedToLoadOrShow('Anúncio não está pronto.');
      loadRewardedAd();
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}
