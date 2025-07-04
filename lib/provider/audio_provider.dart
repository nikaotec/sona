import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/audio_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _service = AudioService();
  AudioModel? _currentAudio;
  bool _isPlaying = false;
  AdService? _adService; // Adicione uma instância de AdService

  AudioModel? get currentAudio => _currentAudio;
  bool get isPlaying => _isPlaying;

  

  // Método para injetar AdService, ou pode ser pego via Provider no playAudio
  void setAdService(AdService adService) {
    _adService = adService;
    _adService?.loadRewardedAd(); // Carrega um anúncio ao definir o serviço
  }

  void _actuallyPlayAudio(AudioModel audio) async {
    _currentAudio = audio;
    await _service.play(audio.url);
    _isPlaying = true;
    notifyListeners();
  }

  void playAudio(BuildContext context, AudioModel audio) async {
    final paywall = Provider.of<PaywallProvider>(context, listen: false);
    _adService ??= Provider.of<AdService>(context, listen: false); 
    await paywall.loadData();

    if (paywall.isPremium) {
      _actuallyPlayAudio(audio);
      return;
    }

    // Verifica se pode reproduzir sem anúncio
    if (paywall.canPlayWithoutAd) {
      await paywall.registerPlay();
      _actuallyPlayAudio(audio);
      return;
    }

    // Precisa assistir anúncio para continuar
    _adService?.showRewardedAd(
      onUserEarnedRewardCallback: () async {
        debugPrint("Usuário ganhou recompensa por assistir o anúncio antes de tocar a música.");
        await paywall.registerRewardedAdWatched();
      },
      onAdDismissed: () {
        debugPrint("Anúncio dispensado, tocando música.");
        _actuallyPlayAudio(audio);
      },
      onAdFailedToLoadOrShow: (error) {
        debugPrint("Falha ao carregar/mostrar anúncio: $error. Redirecionando para paywall.");
        GoRouter.of(context).go('/paywall');
      },
    );
  }

  void pauseAudio() {
    _service.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void stopAudio() {
    _service.stop();
    _isPlaying = false;
    _currentAudio = null;
    notifyListeners();
  }
}
