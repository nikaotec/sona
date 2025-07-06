import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sona/utils/ad_config.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  bool get isRewardedAdReady => _isRewardedAdReady;

  void loadRewardedAd() {
    if (_isRewardedAdReady) return;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          // debugPrint("✅ RewardedAd carregado."); // Removido
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isRewardedAdReady = false;
          // debugPrint("❌ Erro ao carregar RewardedAd: $error"); // Removido
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
            // debugPrint("📺 Anúncio mostrado: $ad"), // Removido
            null,
        onAdDismissedFullScreenContent: (ad) {
          // debugPrint("🔙 Anúncio fechado: $ad"); // Removido
          ad.dispose();
          _isRewardedAdReady = false;
          onAdDismissed();
          loadRewardedAd(); // Pré-carrega o próximo anúncio
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          // debugPrint("❌ Falha ao exibir anúncio: $error"); // Removido
          ad.dispose();
          _isRewardedAdReady = false;
          onAdFailedToLoadOrShow(error.message);
          loadRewardedAd(); // Tenta carregar outro
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // debugPrint("🎉 Usuário ganhou recompensa: ${reward.amount} ${reward.type}"); // Removido
          onUserEarnedRewardCallback();
        },
      );

      _rewardedAd = null; // Previne múltiplos usos
    } else {
      // debugPrint("⚠️ Anúncio não está pronto"); // Removido
      onAdFailedToLoadOrShow("Anúncio não está pronto.");
      loadRewardedAd();
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}


