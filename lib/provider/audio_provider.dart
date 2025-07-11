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
  AudioModel? _currentSound;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isMixMode = false;
  AdService? _adService;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = false;
  
  // Controles de volume para mixagem
  double _musicVolume = 1.0;
  double _soundVolume = 0.7;

  AudioModel? get currentAudio => _currentAudio;
  AudioModel? get currentSound => _currentSound;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isMixMode => _isMixMode;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isLoading => _isLoading;
  double get musicVolume => _musicVolume;
  double get soundVolume => _soundVolume;

  // Stream para posição (compatibilidade)
  Stream<Duration> get positionStream => _service.positionStream;

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
      _isPaused = !playerState.playing && playerState.processingState != ProcessingState.idle;
      _isLoading = playerState.processingState == ProcessingState.loading ||
                   playerState.processingState == ProcessingState.buffering;
      notifyListeners();
    });
  }

  void setAdService(AdService adService) {
    _adService = adService;
    _adService?.loadRewardedAd();
  }

  void _actuallyPlayAudio(AudioModel audio) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Se é o mesmo áudio e está pausado, apenas resume
      if (_currentAudio?.url == audio.url && _isPaused) {
        if (_isMixMode && _currentSound != null) {
          _service.resumeMix();
        } else {
          _service.resumeMusic();
        }
      } else {
        // Se é um novo áudio, carrega e toca
        _currentAudio = audio;
        _isPaused = false;
        
        if (_isMixMode && _currentSound != null) {
          await _service.playMix(audio.url, _currentSound!.url);
        } else {
          await _service.loadMusic(audio.url);
          await _service.playMusic();
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint("Erro ao reproduzir áudio: $e");
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
    if (_isMixMode) {
      _service.pauseMix();
    } else {
      _service.pauseMusic();
    }
    _isPaused = true;
    notifyListeners();
  }

  void resumeAudio() async {
    if (_currentAudio != null) {
      if (_isMixMode && _currentSound != null) {
        _service.resumeMix();
      } else {
        _service.resumeMusic();
      }
      _isPaused = false;
      notifyListeners();
    }
  }

  void togglePlayPause(BuildContext context) {
    if (_currentAudio == null) return;
    
    if (_isPlaying) {
      pauseAudio();
    } else if (_isPaused) {
      resumeAudio();
    } else {
      playAudio(context, _currentAudio!);
    }
  }

  void stopAudio() {
    if (_isMixMode) {
      _service.stopMix();
    } else {
      _service.stopMusic();
    }
    _isPlaying = false;
    _isPaused = false;
    _currentAudio = null;
    _currentSound = null;
    _isMixMode = false;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();
  }

  // Métodos para mixagem
  void enableMixMode(AudioModel soundAudio) {
    _currentSound = soundAudio;
    _isMixMode = true;
    notifyListeners();
  }

  void disableMixMode() {
    if (_isMixMode) {
      _service.stopSound();
      _currentSound = null;
      _isMixMode = false;
      notifyListeners();
    }
  }

  void playMix(BuildContext context, AudioModel musicAudio, AudioModel soundAudio) async {
    _currentAudio = musicAudio;
    _currentSound = soundAudio;
    _isMixMode = true;
    
    final paywall = Provider.of<PaywallProvider>(context, listen: false);
    await paywall.loadData();

    if (paywall.isPremium) {
      _actuallyPlayMix(musicAudio, soundAudio);
      return;
    }

    _adService?.showRewardedAd(
      onUserEarnedRewardCallback: () {
        debugPrint("Usuário ganhou recompensa por assistir o anúncio antes de tocar o mix.");
      },
      onAdDismissed: () {
        debugPrint("Anúncio dispensado, tocando mix.");
        _actuallyPlayMix(musicAudio, soundAudio);
      },
      onAdFailedToLoadOrShow: (error) {
        debugPrint("Falha ao carregar/mostrar anúncio: $error. Tocando mix diretamente.");
        _actuallyPlayMix(musicAudio, soundAudio);
      },
    );
  }

  void _actuallyPlayMix(AudioModel musicAudio, AudioModel soundAudio) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _service.playMix(musicAudio.url, soundAudio.url);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint("Erro ao reproduzir mix: $e");
      notifyListeners();
    }
  }

  // Controles de volume
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _service.setMusicVolume(_musicVolume);
    notifyListeners();
  }

  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
    _service.setSoundVolume(_soundVolume);
    notifyListeners();
  }

  void seek(Duration position) {
    _service.seek(position);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

