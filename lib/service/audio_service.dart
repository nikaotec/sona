import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// Serviço de áudio avançado com suporte para múltiplos players simultâneos
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Mapa de players ativos por ID
  final Map<String, AudioPlayer> _players = {};
  
  // Player principal para controle geral
  AudioPlayer? _mainPlayer;
  
  // Configuração da sessão de áudio
  AudioSession? _audioSession;
  
  // Estado de inicialização
  bool _isInitialized = false;

  /// Inicializa o serviço de áudio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurar sessão de áudio
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      _isInitialized = true;
      debugPrint('EnhancedAudioService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing EnhancedAudioService: $e');
      rethrow;
    }
  }

  /// Cria ou obtém um player por ID
  AudioPlayer getPlayer(String playerId) {
    if (!_players.containsKey(playerId)) {
      _players[playerId] = AudioPlayer();
      debugPrint('Created new player: $playerId');
    }
    return _players[playerId]!;
  }

  /// Define o player principal
  void setMainPlayer(String playerId) {
    _mainPlayer = getPlayer(playerId);
    debugPrint('Main player set to: $playerId');
  }

  /// Carrega áudio em um player específico
  Future<void> loadAudio(String playerId, String url) async {
    await initialize();
    
    final player = getPlayer(playerId);
    
    try {
      if (url.startsWith('assets/')) {
        await player.setAsset(url);
      } else {
        await player.setUrl(url);
      }
      debugPrint('Audio loaded in player $playerId: $url');
    } catch (e) {
      debugPrint('Error loading audio in player $playerId: $e');
      rethrow;
    }
  }

  /// Reproduz áudio em um player específico
  Future<void> play(String playerId) async {
    final player = getPlayer(playerId);
    await player.play();
    debugPrint('Playing audio in player: $playerId');
  }

  /// Pausa áudio em um player específico
  void pause(String playerId) {
    final player = _players[playerId];
    if (player != null) {
      player.pause();
      debugPrint('Paused audio in player: $playerId');
    }
  }

  /// Para áudio em um player específico
  void stop(String playerId) {
    final player = _players[playerId];
    if (player != null) {
      player.stop();
      debugPrint('Stopped audio in player: $playerId');
    }
  }

  /// Para todos os players
  void stopAll() {
    for (final entry in _players.entries) {
      entry.value.stop();
      debugPrint('Stopped player: ${entry.key}');
    }
  }

  /// Pausa todos os players
  void pauseAll() {
    for (final entry in _players.entries) {
      entry.value.pause();
      debugPrint('Paused player: ${entry.key}');
    }
  }

  /// Define volume para um player específico
  Future<void> setVolume(String playerId, double volume) async {
    final player = _players[playerId];
    if (player != null) {
      await player.setVolume(volume.clamp(0.0, 1.0));
      debugPrint('Set volume for player $playerId: $volume');
    }
  }

  /// Define volume para todos os players
  Future<void> setVolumeAll(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    for (final entry in _players.entries) {
      await entry.value.setVolume(clampedVolume);
    }
    debugPrint('Set volume for all players: $clampedVolume');
  }

  /// Busca posição em um player específico
  Future<void> seek(String playerId, Duration position) async {
    final player = _players[playerId];
    if (player != null) {
      await player.seek(position);
      debugPrint('Seeked player $playerId to: $position');
    }
  }

  /// Obtém stream de posição de um player
  Stream<Duration> getPositionStream(String playerId) {
    final player = _players[playerId];
    return player?.positionStream ?? const Stream.empty();
  }

  /// Obtém stream de duração de um player
  Stream<Duration?> getDurationStream(String playerId) {
    final player = _players[playerId];
    return player?.durationStream ?? const Stream.empty();
  }

  /// Obtém stream de estado de um player
  Stream<PlayerState> getPlayerStateStream(String playerId) {
    final player = _players[playerId];
    return player?.playerStateStream ?? const Stream.empty();
  }

  /// Verifica se um player está tocando
  bool isPlaying(String playerId) {
    final player = _players[playerId];
    return player?.playing ?? false;
  }

  /// Obtém a duração atual de um player
  Duration? getDuration(String playerId) {
    final player = _players[playerId];
    return player?.duration;
  }

  /// Obtém a posição atual de um player
  Duration getPosition(String playerId) {
    final player = _players[playerId];
    return player?.position ?? Duration.zero;
  }

  /// Remove um player específico
  void removePlayer(String playerId) {
    final player = _players.remove(playerId);
    if (player != null) {
      player.dispose();
      debugPrint('Removed player: $playerId');
    }
  }

  /// Cria um mix de múltiplos áudios
  Future<void> createMix(Map<String, String> audioSources) async {
    await initialize();
    
    // Para todos os players existentes
    stopAll();
    
    // Carrega e reproduz cada áudio
    for (final entry in audioSources.entries) {
      await loadAudio(entry.key, entry.value);
      await play(entry.key);
    }
    
    debugPrint('Created mix with ${audioSources.length} audio sources');
  }

  /// Adiciona áudio ao mix atual
  Future<void> addToMix(String playerId, String url, {double volume = 1.0}) async {
    await loadAudio(playerId, url);
    await setVolume(playerId, volume);
    await play(playerId);
    debugPrint('Added to mix: $playerId');
  }

  /// Remove áudio do mix
  void removeFromMix(String playerId) {
    stop(playerId);
    removePlayer(playerId);
    debugPrint('Removed from mix: $playerId');
  }

  /// Obtém lista de players ativos
  List<String> getActivePlayers() {
    return _players.keys.toList();
  }

  /// Verifica se há algum player tocando
  bool get hasPlayingAudio {
    return _players.values.any((player) => player.playing);
  }

  /// Obtém o player principal
  AudioPlayer? get mainPlayer => _mainPlayer;

  /// Limpa todos os recursos
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _mainPlayer = null;
    _isInitialized = false;
    debugPrint('EnhancedAudioService disposed');
  }

  /// Configurações avançadas para segundo plano (preparação futura)
  Future<void> enableBackgroundPlayback() async {
    // Implementação futura para reprodução em segundo plano
    debugPrint('Background playback configuration ready for implementation');
  }

  /// Configurações de cache (preparação futura)
  Future<void> enableCaching() async {
    // Implementação futura para cache de áudio
    debugPrint('Audio caching configuration ready for implementation');
  }
}
