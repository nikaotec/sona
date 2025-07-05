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
  AdService? _adService;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  AudioModel? get currentAudio => _currentAudio;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  AudioProvider() {
    _service.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    _service.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  void setAdService(AdService adService) {
    _adService = adService;
    _adService?.loadRewardedAd();
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

    _adService?.showRewardedAd(
      onUserEarnedRewardCallback: () {
        debugPrint("Usuário ganhou recompensa por assistir o anúncio antes de tocar a música.");
      },
      onAdDismissed: () {
        debugPrint("Anúncio dispensado, tocando música.");
        _actuallyPlayAudio(audio);
      },
      onAdFailedToLoadOrShow: (error) {
        debugPrint("Falha ao carregar/mostrar anúncio: $error. Tocando música diretamente.");
        _actuallyPlayAudio(audio);
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
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();
  }

  void seek(Duration position) {
    _service.seek(position);
  }
}

