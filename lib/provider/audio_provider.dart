import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _service = AudioService();
  AudioModel? _currentAudio;
  bool _isPlaying = false;
  AdService? _adService;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = false;
  
  // Lista para armazenar o mix de músicas
  final List<AudioModel> _mixPlaylist = [];

  AudioModel? get currentAudio => _currentAudio;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isLoading => _isLoading;
  List<AudioModel> get mixPlaylist => List.unmodifiable(_mixPlaylist);

  AudioProvider() {
    _service.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    
    _service.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Escuta mudanças no estado do player
    _service.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      _isLoading = playerState.processingState == ProcessingState.loading ||
                   playerState.processingState == ProcessingState.buffering;
      notifyListeners();
    });
  }

  void setAdService(AdService adService) {
    _adService = adService;
    _adService?.loadRewardedAd();
  }

  // Método para adicionar música ao mix
  void addToMix(AudioModel audio) {
    // Verifica se a música já não está no mix
    if (!_mixPlaylist.any((item) => item.url == audio.url)) {
      _mixPlaylist.add(audio);
      notifyListeners();
    }
  }

  // Método para remover música do mix
  void removeFromMix(AudioModel audio) {
    _mixPlaylist.removeWhere((item) => item.url == audio.url);
    notifyListeners();
  }

  // Método para verificar se uma música está no mix
  bool isInMix(AudioModel audio) {
    return _mixPlaylist.any((item) => item.url == audio.url);
  }

  // Método para limpar o mix
  void clearMix() {
    _mixPlaylist.clear();
    notifyListeners();
  }

  // Método para obter o número de músicas no mix
  int get mixCount => _mixPlaylist.length;

  void _actuallyPlayAudio(AudioModel audio) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Se é o mesmo áudio e está pausado, apenas resume
      if (_currentAudio?.url == audio.url && !_isPlaying) {
         _service.resume(); 
      } else {
        // Se é um novo áudio ou o áudio atual não está pausado, carrega e toca
        _currentAudio = audio;
        await _service.load(audio.url); // Carrega o áudio
        await _service.play(); // Toca o áudio
      }
      
      _isLoading = false;
      // debugPrint("Erro ao reproduzir áudio: $e");
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      // debugPrint("Erro ao reproduzir áudio: $e");
      notifyListeners();
    }
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
        // debugPrint("Usuário ganhou recompensa por assistir o anúncio antes de tocar a música.");
      },
      onAdDismissed: () {
        // debugPrint("Anúncio dispensado, tocando música.");
        _actuallyPlayAudio(audio);
      },
      onAdFailedToLoadOrShow: (error) {
        // debugPrint("Falha ao carregar/mostrar anúncio: $error. Tocando música diretamente.");
        _actuallyPlayAudio(audio);
      },
    );
  }

  void pauseAudio() {
    _service.pause();
    notifyListeners();
  }

  void resumeAudio() async {
    if (_currentAudio != null) {
      _service.resume(); 
      notifyListeners();
    }
  }

  void togglePlayPause(BuildContext context) {
    if (_currentAudio == null) return;
    
    if (_isPlaying) {
      pauseAudio();
    } else {
      // Se não está tocando, resume de onde parou
      resumeAudio();
    }
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

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }
}
