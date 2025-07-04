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
    // AdService pode ser obtido via Provider se estiver registrado no main.dart
    _adService ??= Provider.of<AdService>(context, listen: false); 
    await paywall.loadData(); // Garante que os dados do paywall estão carregados

    if (paywall.isPremium) {
      _actuallyPlayAudio(audio);
      return;
    }

    // Tenta registrar a reprodução. Isso incrementará dailyPlayCount.
    bool canPlayWithoutPaywall = await paywall.registerPlay();

//     if (!canPlayWithoutPaywall) { // Atingiu o limite e não é premium
//       GoRouter.of(context).go('/paywall');
// ;
//       return;
//     }

    // Verifica se é o momento de mostrar o anúncio (após a 3ª música, ou seja, dailyPlayCount se tornou >= 3 AQUI)
    // O registerPlay já incrementou, então verificamos se é >= 3
    // E como já sabemos que não é premium, não precisamos checar paywall.isPremium de novo.
    if (paywall.dailyPlayCount >= 3) { 
      _adService?.showRewardedAd(
        onUserEarnedRewardCallback: () {
          debugPrint("Usuário ganhou recompensa por assistir o anúncio antes de tocar a música.");
          // Poderia-se resetar o dailyPlayCount aqui se essa fosse a regra de negócio,
          // mas a regra original é "após 3 músicas", não "a cada 3 músicas".
        },
        onAdDismissed: () {
          debugPrint("Anúncio dispensado, tocando música.");
          _actuallyPlayAudio(audio);
        },
        onAdFailedToLoadOrShow: (error) {
          debugPrint("Falha ao carregar/mostrar anúncio: $error. Tocando música diretamente.");
          _actuallyPlayAudio(audio); // Toca o áudio mesmo se o anúncio falhar
        },
      );
    } else {
      // Menos de 3 reproduções, toca diretamente
      _actuallyPlayAudio(audio);
    }
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
