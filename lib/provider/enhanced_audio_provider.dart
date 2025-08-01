import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/enhanced_audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sona/model/mix_track_model.dart'; // Importar MixTrackModel

/// Provider de áudio avançado com suporte para múltiplos players simultâneos
class EnhancedAudioProvider extends ChangeNotifier {
  final EnhancedAudioService _audioService = EnhancedAudioService();
  
  // Player principal
  static const String mainPlayerId = 'main_player';
  
  // Estado do player principal
  AudioModel? _currentAudio;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // Mix de áudios ativos
  final Map<String, AudioModel> _activeMix = {};
  final Map<String, double> _mixVolumes = {};
  
  // Serviço de anúncios
  AdService? _adService;
  
  // Getters para o player principal
  AudioModel? get currentAudio => _currentAudio;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  
  // Getters para mix
  Map<String, AudioModel> get activeMix => Map.unmodifiable(_activeMix);
  Map<String, double> get mixVolumes => Map.unmodifiable(_mixVolumes);
  bool get hasMixActive => _activeMix.isNotEmpty;
  int get mixCount => _activeMix.length;
  bool get isAnyMixPlaying => _audioService.hasPlayingMixAudio; 

  // NOVO GETTER: Retorna uma lista de MixTrackModel para o mix
  List<MixTrackModel> get mixTracks {
    return _activeMix.keys.map((playerId) {
      final audio = _activeMix[playerId]!;
      final volume = _mixVolumes[playerId]!;
      final isPlaying = _audioService.isPlaying(playerId);
      return MixTrackModel(
        id: audio.id,
        audio: audio,
        player: _audioService.getPlayer(playerId), // Obter o player real
        volume: volume,
        isPlaying: isPlaying,
        isLoaded: true, // Assumimos que está carregado se está no mix
      );
    }).toList();
  }

  EnhancedAudioProvider() {
    _initializeProvider();
  }

  /// Inicializa o provider e configura listeners
  Future<void> _initializeProvider() async {
    await _audioService.initialize();
    _audioService.setMainPlayer(mainPlayerId);
    _setupMainPlayerListeners();
  }

  /// Configura listeners para o player principal
  void _setupMainPlayerListeners() {
    // Position stream
    _audioService.getPositionStream(mainPlayerId).listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    
    // Duration stream
    _audioService.getDurationStream(mainPlayerId).listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Player state stream
    _audioService.getPlayerStateStream(mainPlayerId).listen((playerState) {
      _isPlaying = playerState.playing;
      _isLoading = playerState.processingState == ProcessingState.loading ||
                   playerState.processingState == ProcessingState.buffering;
      notifyListeners();
    });
  }

  /// Define o serviço de anúncios
  void setAdService(AdService adService) {
    _adService = adService;
    _adService?.loadRewardedAd();
  }

  /// Reproduz áudio no player principal
  Future<void> playMainAudio(BuildContext context, AudioModel audio) async {
    final paywall = Provider.of<PaywallProvider>(context, listen: false);
    _adService ??= Provider.of<AdService>(context, listen: false);
    await paywall.loadData();

    if (paywall.isPremium) {
      await _actuallyPlayMainAudio(audio);
      return;
    }

    _adService?.showRewardedAd(
      onUserEarnedRewardCallback: () {
        debugPrint("Usuário ganhou recompensa por assistir o anúncio");
      },
      onAdDismissed: () {
        _actuallyPlayMainAudio(audio);
      },
      onAdFailedToLoadOrShow: (error) {
        debugPrint("Falha no anúncio: $error. Tocando música diretamente.");
        _actuallyPlayMainAudio(audio);
      },
    );
  }

  /// Execução real da reprodução do áudio principal
  Future<void> _actuallyPlayMainAudio(AudioModel audio) async {
    try {
      _isLoading = true;
      // Define _currentAudio antes de notificar os listeners
      // para que o PlayerScreen tenha o áudio disponível imediatamente.
      _currentAudio = audio;
      notifyListeners();
      
      // Se é o mesmo áudio e está pausado, apenas resume
      if (_audioService.isPlaying(mainPlayerId) && _currentAudio?.url == audio.url) {
        await _audioService.play(mainPlayerId);
      } else {
        // Carrega e toca novo áudio
        await _audioService.loadAudio(mainPlayerId, audio.url);
        await _audioService.play(mainPlayerId);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint("Erro ao reproduzir áudio principal: $e");
      notifyListeners();
      // Limpa o currentAudio em caso de erro para evitar estado inconsistente
      _currentAudio = null;
    }
  }

  /// Pausa o player principal
  void pauseMainAudio() {
    _audioService.pause(mainPlayerId);
    notifyListeners();
  }

  /// Resume o player principal
  Future<void> resumeMainAudio() async {
    if (_currentAudio != null) {
      await _audioService.play(mainPlayerId);
      notifyListeners();
    }
  }

  /// Toggle play/pause do player principal
  void toggleMainPlayPause(BuildContext context) {
    if (_currentAudio == null) return;
    
    if (_isPlaying) {
      pauseMainAudio();
    } else {
      resumeMainAudio();
    }
  }

  /// Para o player principal
  void stopMainAudio() {
    _audioService.stop(mainPlayerId);
    _currentAudio = null;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();
  }

  /// Busca posição no player principal
  Future<void> seekMainAudio(Duration position) async {
    await _audioService.seek(mainPlayerId, position);
  }

  /// Define volume do player principal
  Future<void> setMainVolume(double volume) async {
    await _audioService.setVolume(mainPlayerId, volume);
  }

  // ========== FUNCIONALIDADES DE MIX ==========

  /// Carrega uma lista de áudios no mix (substitui o mix atual)
  Future<void> loadMix(List<AudioModel> audios) async {
    // Limpa o mix atual
    clearMix();
    
    // Adiciona cada áudio ao mix
    for (final audio in audios) {
      await addToMix(audio, volume: audio.volume ?? 0.7);
    }
    
    debugPrint("Mix carregado com ${audios.length} áudios");
  }

  /// Adiciona áudio ao mix
  Future<void> addToMix(AudioModel audio, {double volume = 1.0}) async {
    try {
      final playerId = 'mix_${audio.id}';
      
      // Verifica se já existe no mix para evitar duplicação
      if (_activeMix.containsKey(playerId)) {
        debugPrint("Áudio ${audio.title} já está no mix");
        return;
      }
      
      await _audioService.addToMix(playerId, audio.url, volume: volume);
      
      _activeMix[playerId] = audio;
      _mixVolumes[playerId] = volume;
      
      notifyListeners();
      debugPrint("Adicionado ao mix: ${audio.title}");
    } catch (e) {
      debugPrint("Erro ao adicionar ao mix: $e");
    }
  }

  /// Remove áudio do mix
  void removeFromMix(String audioId) {
    final playerId = 'mix_$audioId';
    
    _audioService.removeFromMix(playerId);
    _activeMix.remove(playerId);
    _mixVolumes.remove(playerId);
    
    notifyListeners();
    debugPrint("Removido do mix: $audioId");
  }

  /// Limpa todo o mix
  void clearMix() {
    for (final playerId in _activeMix.keys.toList()) {
      _audioService.removeFromMix(playerId);
    }
    
    _activeMix.clear();
    _mixVolumes.clear();
    
    notifyListeners();
    debugPrint("Mix limpo");
  }

  /// Define volume de um áudio específico no mix
  Future<void> setMixAudioVolume(String audioId, double volume) async {
    final playerId = 'mix_$audioId';
    
    if (_activeMix.containsKey(playerId)) {
      await _audioService.setVolume(playerId, volume);
      _mixVolumes[playerId] = volume;
      notifyListeners();
    }
  }

  /// Pausa todo o mix
  void pauseMix() {
    for (final playerId in _activeMix.keys) {
      _audioService.pause(playerId);
    }
    notifyListeners();
  }

  /// Resume todo o mix
  Future<void> resumeMix() async {
    for (final playerId in _activeMix.keys) {
      await _audioService.play(playerId);
    }
    notifyListeners();
  }

  /// Pausa um áudio específico no mix
  void pauseMixTrack(String audioId) {
    final playerId = 'mix_$audioId';
    if (_activeMix.containsKey(playerId)) {
      _audioService.pause(playerId);
      notifyListeners();
    }
  }

  /// Resume um áudio específico no mix
  Future<void> resumeMixTrack(String audioId) async {
    final playerId = 'mix_$audioId';
    if (_activeMix.containsKey(playerId)) {
      await _audioService.play(playerId);
      notifyListeners();
    }
  }

  /// Verifica se um áudio está no mix
  bool isInMix(String audioId) {
    return _activeMix.containsKey('mix_$audioId');
  }

  /// Obtém volume de um áudio no mix
  double getMixAudioVolume(String audioId) {
    return _mixVolumes['mix_$audioId'] ?? 1.0;
  }

  // ========== FUNCIONALIDADES AVANÇADAS ==========

  /// Cria um mix predefinido
  Future<void> createPresetMix(List<AudioModel> audios, {Map<String, double>? volumes}) async {
    clearMix();
    
    for (int i = 0; i < audios.length; i++) {
      final audio = audios[i];
      final volume = volumes?[audio.id] ?? 1.0;
      await addToMix(audio, volume: volume);
    }
    
    debugPrint("Mix predefinido criado com ${audios.length} áudios");
  }

  /// Para todos os áudios (principal + mix)
  void stopAll() {
    _audioService.stopAll();
    _currentAudio = null;
    _activeMix.clear();
    _mixVolumes.clear();
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();
  }

  /// Pausa todos os áudios (principal + mix)
  void pauseAll() {
    _audioService.pauseAll();
    notifyListeners();
  }

  /// Define volume global para todos os players
  Future<void> setGlobalVolume(double volume) async {
    await _audioService.setVolumeAll(volume);
  }

  /// Obtém lista de players ativos
  List<String> getActivePlayers() {
    return _audioService.getActivePlayers();
  }

  /// Verifica se há algum áudio tocando
  bool get hasAnyAudioPlaying {
    return _audioService.hasPlayingAudio;
  }

  // ========== PREPARAÇÃO PARA FUNCIONALIDADES FUTURAS ==========

  /// Habilita reprodução em segundo plano (preparação futura)
  Future<void> enableBackgroundPlayback() async {
    await _audioService.enableBackgroundPlayback();
  }

  /// Habilita cache de áudio (preparação futura)
  Future<void> enableCaching() async {
    await _audioService.enableCaching();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  // ========== MÉTODOS DE COMPATIBILIDADE ==========
  
  /// Métodos para manter compatibilidade com o provider antigo
  void playAudio(BuildContext context, AudioModel audio) {
    playMainAudio(context, audio);
  }

  void pauseAudio() {
    pauseMainAudio();
  }

  void resumeAudio() {
    resumeAudio();
  }

  void togglePlayPause(BuildContext context) {
    toggleMainPlayPause(context);
  }

  void stopAudio() {
    stopMainAudio();
  }

  void seek(Duration position) {
    seekMainAudio(position);
  }
}
