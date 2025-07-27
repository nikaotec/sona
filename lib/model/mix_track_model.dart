import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:go_router/go_router.dart';

// Modelo para faixas do mix
class MixTrack {
  final AudioModel audio;
  final AudioPlayer player;
  double volume;
  bool isPlaying;
  bool isLoaded;

  MixTrack({
    required this.audio,
    required this.player,
    this.volume = 0.7,
    this.isPlaying = false,
    this.isLoaded = false,
  });
}

class EnhancedAudioProvider with ChangeNotifier {
  // Player principal para música individual
  final AudioPlayer _mainPlayer = AudioPlayer();
  
  // Lista de players para o mix
  final List<MixTrack> _mixTracks = [];
  
  // Estado do player principal
  AudioModel? _currentAudio;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // Estado do mix
  double _masterVolume = 0.8;
  bool _isMixMode = false;
  
  // Getters para o player principal
  AudioModel? get currentAudio => _currentAudio;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  
  // Getters para o mix
  List<MixTrack> get mixTracks => List.unmodifiable(_mixTracks);
  double get masterVolume => _masterVolume;
  bool get hasMixActive => _mixTracks.isNotEmpty;
  int get mixCount => _mixTracks.length;
  bool get isAnyMixPlaying => _mixTracks.any((track) => track.isPlaying);
  bool get isMixMode => _isMixMode;

  EnhancedAudioProvider() {
    _initializeMainPlayer();
  }

  void _initializeMainPlayer() {
    // Listener para posição
    _mainPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listener para duração
    _mainPlayer.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Listener para estado de reprodução
    _mainPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
                   state.processingState == ProcessingState.buffering;
      notifyListeners();
    });
  }

  // Métodos do player principal
  Future<void> playMainAudio(BuildContext context, AudioModel audio) async {
    try {
      final paywallProvider = Provider.of<PaywallProvider>(context, listen: false);
      
      // Verificar se é premium e o usuário tem acesso
      if (audio.isPremium && !paywallProvider.isPremium) {
        final adService = Provider.of<AdService>(context, listen: false);
        bool canPlay = false;
        adService.showRewardedAd(
          onUserEarnedRewardCallback: () {
            canPlay = true;
          },
          onAdDismissed: () {
            if (!canPlay) {
              // Mostrar paywall
              context.go('/paywall');
            }
          },
          onAdFailedToLoadOrShow: (String error) {
            // Mostrar paywall se o anúncio falhar
            context.go('/paywall');
          },
        );
        if (!canPlay) {
          return;
        }
      }

      await _actuallyPlayMainAudio(context, audio);
    } catch (e) {
      debugPrint('Erro ao reproduzir áudio: $e');
      _currentAudio = null;
      notifyListeners();
    }
  }

  Future<void> _actuallyPlayMainAudio(BuildContext context, AudioModel audio) async {
    try {
      // Definir o áudio atual imediatamente
      _currentAudio = audio;
      _isLoading = true;
      notifyListeners();

      // Parar o player atual se estiver tocando
      await _mainPlayer.stop();

      // Carregar o novo áudio
      if (audio.url.startsWith('assets/')) {
        await _mainPlayer.setAsset(audio.url);
      } else {
        await _mainPlayer.setUrl(audio.url);
      }

      // Reproduzir
      await _mainPlayer.play();
      
      _isLoading = false;
      notifyListeners();

      // Navegar para a tela do player se não estiver lá
      if (context.mounted) {
        final currentRoute = GoRouterState.of(context).uri.toString();
        if (currentRoute != '/player') {
          context.go('/player');
        }
      }
    } catch (e) {
      _currentAudio = null;
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleMainPlayPause(BuildContext context) async {
    if (_currentAudio == null) return;

    try {
      if (_isPlaying) {
        await _mainPlayer.pause();
      } else {
        await _mainPlayer.play();
      }
    } catch (e) {
      debugPrint('Erro ao alternar play/pause: $e');
    }
  }

  Future<void> seekMainAudio(Duration position) async {
    try {
      await _mainPlayer.seek(position);
    } catch (e) {
      debugPrint('Erro ao buscar posição: $e');
    }
  }

  Future<void> stopMainAudio() async {
    try {
      await _mainPlayer.stop();
      _currentAudio = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao parar áudio: $e');
    }
  }

  // Métodos do mix
  Future<void> addToMix(AudioModel audio) async {
    try {
      // Verificar se já está no mix
      if (isInMix(audio.id)) {
        return;
      }

      // Criar novo player para esta faixa
      final player = AudioPlayer();
      final mixTrack = MixTrack(
        audio: audio,
        player: player,
        volume: 0.7,
      );

      // Configurar listeners para este player
      _setupMixTrackListeners(mixTrack);

      // Carregar o áudio
      await _loadMixTrack(mixTrack);

      // Adicionar à lista
      _mixTracks.add(mixTrack);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao adicionar ao mix: $e');
    }
  }

  void _setupMixTrackListeners(MixTrack track) {
    // Listener para estado de reprodução
    track.player.playerStateStream.listen((state) {
      track.isPlaying = state.playing;
      notifyListeners();
    });

    // Configurar loop infinito
    track.player.setLoopMode(LoopMode.one);
  }

  Future<void> _loadMixTrack(MixTrack track) async {
    try {
      if (track.audio.url.startsWith('assets/')) {
        await track.player.setAsset(track.audio.url);
      } else {
        await track.player.setUrl(track.audio.url);
      }
      
      // Definir volume inicial
      await track.player.setVolume(track.volume * _masterVolume);
      track.isLoaded = true;
    } catch (e) {
      debugPrint('Erro ao carregar faixa do mix: $e');
      track.isLoaded = false;
    }
  }

  Future<void> removeFromMix(String audioId) async {
    try {
      final index = _mixTracks.indexWhere((track) => track.audio.id == audioId);
      if (index != -1) {
        final track = _mixTracks[index];
        await track.player.dispose();
        _mixTracks.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao remover do mix: $e');
    }
  }

  bool isInMix(String audioId) {
    return _mixTracks.any((track) => track.audio.id == audioId);
  }

  Future<void> toggleMixTrack(String audioId) async {
    try {
      final track = _mixTracks.firstWhere((t) => t.audio.id == audioId);
      
      if (track.isPlaying) {
        await track.player.pause();
      } else {
        if (!track.isLoaded) {
          await _loadMixTrack(track);
        }
        await track.player.play();
      }
    } catch (e) {
      debugPrint('Erro ao alternar faixa do mix: $e');
    }
  }

  Future<void> setMixTrackVolume(String audioId, double volume) async {
    try {
      final track = _mixTracks.firstWhere((t) => t.audio.id == audioId);
      track.volume = volume;
      await track.player.setVolume(volume * _masterVolume);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao definir volume da faixa: $e');
    }
  }

  Future<void> setMasterVolume(double volume) async {
    try {
      _masterVolume = volume;
      
      // Aplicar o volume master a todas as faixas do mix
      for (final track in _mixTracks) {
        await track.player.setVolume(track.volume * _masterVolume);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao definir volume master: $e');
    }
  }

  Future<void> playAll() async {
    try {
      for (final track in _mixTracks) {
        if (!track.isLoaded) {
          await _loadMixTrack(track);
        }
        if (!track.isPlaying) {
          await track.player.play();
        }
      }
    } catch (e) {
      debugPrint('Erro ao tocar todas as faixas: $e');
    }
  }

  Future<void> pauseAll() async {
    try {
      for (final track in _mixTracks) {
        if (track.isPlaying) {
          await track.player.pause();
        }
      }
    } catch (e) {
      debugPrint('Erro ao pausar todas as faixas: $e');
    }
  }

  Future<void> stopAll() async {
    try {
      for (final track in _mixTracks) {
        await track.player.stop();
      }
    } catch (e) {
      debugPrint('Erro ao parar todas as faixas: $e');
    }
  }

  Future<void> clearMix() async {
    try {
      // Parar e descartar todos os players
      for (final track in _mixTracks) {
        await track.player.dispose();
      }
      
      _mixTracks.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao limpar mix: $e');
    }
  }

  void setMixMode(bool enabled) {
    _isMixMode = enabled;
    notifyListeners();
  }

  // Métodos de salvamento e carregamento de mix
  Map<String, dynamic> exportMixData() {
    return {
      'name': 'Meu Mix',
      'tracks': _mixTracks.map((track) => {
        'audio': track.audio.toMap(),
        'volume': track.volume,
      }).toList(),
      'masterVolume': _masterVolume,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> loadMixFromData(Map<String, dynamic> data) async {
    try {
      // Limpar mix atual
      await clearMix();
      
      // Carregar volume master
      _masterVolume = data['masterVolume'] ?? 0.8;
      
      // Carregar faixas
      final tracks = data['tracks'] as List<dynamic>? ?? [];
      for (final trackData in tracks) {
        final audioData = trackData['audio'] as Map<String, dynamic>;
        final audio = AudioModel.fromMap(audioData);
        
        await addToMix(audio);
        
        // Definir volume da faixa
        final volume = trackData['volume'] as double? ?? 0.7;
        await setMixTrackVolume(audio.id, volume);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar mix: $e');
    }
  }

  @override
  void dispose() {
    _mainPlayer.dispose();
    
    // Descartar todos os players do mix
    for (final track in _mixTracks) {
      track.player.dispose();
    }
    
    super.dispose();
  }
}
