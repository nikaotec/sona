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

  // Funcionalidade de Mix
  List<AudioModel> _currentMix = [];
  int _currentMixIndex = 0;
  bool _isMixPlaying = false;
  bool _isLoopEnabled = false;
  bool _isShuffleEnabled = false;

  AudioModel? get currentAudio => _currentAudio;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isLoading => _isLoading;

  // Getters para Mix
  List<AudioModel> get currentMix => List.unmodifiable(_currentMix);
  int get currentMixIndex => _currentMixIndex;
  bool get isMixPlaying => _isMixPlaying;
  bool get isLoopEnabled => _isLoopEnabled;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get hasMix => _currentMix.isNotEmpty;
  int get mixCount => _currentMix.length;

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
      
      // Verifica se a música terminou para tocar a próxima no mix
      if (playerState.processingState == ProcessingState.completed && _isMixPlaying) {
        _playNextInMix();
      }
      
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
      if (_currentAudio?.url == audio.url && !_isPlaying) {
         _service.resume(); 
      } else {
        // Se é um novo áudio ou o áudio atual não está pausado, carrega e toca
        _currentAudio = audio;
        await _service.load(audio.url); // Carrega o áudio
        await _service.play(); // Toca o áudio
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void playAudio(BuildContext context, AudioModel audio) async {
    final paywall = Provider.of<PaywallProvider>(context, listen: false);
    _adService ??= Provider.of<AdService>(context, listen: false);
    await paywall.loadData();

    // Para áudio individual, limpa o mix
    _clearMix();

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

  // Método para tocar um mix de áudios
  void playMix(List<AudioModel> audios, {bool loop = false, bool shuffle = false}) async {
    if (audios.isEmpty) return;

    _currentMix = List.from(audios);
    _isLoopEnabled = loop;
    _isShuffleEnabled = shuffle;
    _isMixPlaying = true;
    _currentMixIndex = 0;

    if (shuffle) {
      _currentMix.shuffle();
    }

    await _playAudioFromMix(_currentMixIndex);
  }

  // Toca um áudio específico do mix
  Future<void> _playAudioFromMix(int index) async {
    if (index < 0 || index >= _currentMix.length) return;

    _currentMixIndex = index;
    final audio = _currentMix[index];
    
    try {
      _isLoading = true;
      notifyListeners();
      
      _currentAudio = audio;
      await _service.load(audio.url);
      await _service.play();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Se falhar, tenta a próxima música
      _playNextInMix();
    }
  }

  // Toca a próxima música do mix
  void _playNextInMix() async {
    if (!_isMixPlaying || _currentMix.isEmpty) return;

    int nextIndex = _currentMixIndex + 1;

    // Se chegou ao fim da lista
    if (nextIndex >= _currentMix.length) {
      if (_isLoopEnabled) {
        // Se loop está ativado, volta para o início
        nextIndex = 0;
      } else {
        // Se não há loop, para o mix
        _stopMix();
        return;
      }
    }

    await _playAudioFromMix(nextIndex);
  }

  // Toca a música anterior do mix
  void playPreviousInMix() async {
    if (!_isMixPlaying || _currentMix.isEmpty) return;

    int previousIndex = _currentMixIndex - 1;

    // Se está no início da lista
    if (previousIndex < 0) {
      if (_isLoopEnabled) {
        // Se loop está ativado, vai para o final
        previousIndex = _currentMix.length - 1;
      } else {
        // Se não há loop, fica na primeira música
        previousIndex = 0;
      }
    }

    await _playAudioFromMix(previousIndex);
  }

  // Força a próxima música do mix
  void playNextInMix() async {
    _playNextInMix();
  }

  // Para o mix
  void _stopMix() {
    _isMixPlaying = false;
    _currentMix.clear();
    _currentMixIndex = 0;
    _isLoopEnabled = false;
    _isShuffleEnabled = false;
    stopAudio();
  }

  // Limpa o mix sem parar a reprodução atual
  void _clearMix() {
    _isMixPlaying = false;
    _currentMix.clear();
    _currentMixIndex = 0;
    _isLoopEnabled = false;
    _isShuffleEnabled = false;
  }

   

  // Pausa o mix
  void pauseMix() {
    if (_isMixPlaying) {
      pauseAudio();
    }
  }

  // Resume o mix
  void resumeMix() {
    if (_isMixPlaying) {
      resumeAudio();
    }
  }

  // Para completamente o mix
  void stopMix() {
    _stopMix();
  }

  // Toggle loop no mix
  void toggleLoop() {
    _isLoopEnabled = !_isLoopEnabled;
    notifyListeners();
  }

  // Toggle shuffle no mix
  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    
    if (_isShuffleEnabled && _isMixPlaying) {
      // Reorganiza o mix mantendo a música atual
      final currentAudio = _currentMix[_currentMixIndex];
      _currentMix.shuffle();
      
      // Encontra a nova posição da música atual
      _currentMixIndex = _currentMix.indexWhere((audio) => audio.id == currentAudio.id);
      if (_currentMixIndex == -1) _currentMixIndex = 0;
    }
    
    notifyListeners();
  }

  // Adiciona áudio ao mix atual
  void addToCurrentMix(AudioModel audio) {
    if (!_currentMix.any((a) => a.id == audio.id)) {
      _currentMix.add(audio);
      notifyListeners();
    }
  }

  // Remove áudio do mix atual
  void removeFromCurrentMix(AudioModel audio) {
    final index = _currentMix.indexWhere((a) => a.id == audio.id);
    if (index != -1) {
      _currentMix.removeAt(index);
      
      // Ajusta o índice atual se necessário
      if (index < _currentMixIndex) {
        _currentMixIndex--;
      } else if (index == _currentMixIndex) {
        // Se removeu a música atual, para ou vai para a próxima
        if (_currentMix.isEmpty) {
          _stopMix();
        } else {
          // Ajusta o índice para não sair dos limites
          if (_currentMixIndex >= _currentMix.length) {
            _currentMixIndex = _currentMix.length - 1;
          }
          _playAudioFromMix(_currentMixIndex);
        }
      }
      
      notifyListeners();
    }
  }

  // Métodos originais mantidos
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

  // Método de conveniência para verificar se um áudio está no mix atual
  bool isAudioInCurrentMix(AudioModel audio) {
    return _currentMix.any((a) => a.id == audio.id);
  }

  // Obtém informações do mix atual
  Map<String, dynamic> get currentMixInfo {
    if (!_isMixPlaying || _currentMix.isEmpty) {
      return {
        'isPlaying': false,
        'currentIndex': 0,
        'totalTracks': 0,
        'currentTrack': null,
        'isLoop': false,
        'isShuffle': false,
      };
    }

    return {
      'isPlaying': _isMixPlaying,
      'currentIndex': _currentMixIndex + 1,
      'totalTracks': _currentMix.length,
      'currentTrack': _currentAudio,
      'isLoop': _isLoopEnabled,
      'isShuffle': _isShuffleEnabled,
    };
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }
}

