import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioService {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _soundPlayer = AudioPlayer();
  AudioSession? _session;
  
  // Estado dos players
  bool _isMusicPlaying = false;
  bool _isSoundPlaying = false;
  
  // Volumes individuais
  double _musicVolume = 1.0;
  double _soundVolume = 1.0;
  
  // URLs atuais
  String? _currentMusicUrl;
  String? _currentSoundUrl;
  
  // Posição salva para resume
  Duration? _lastMusicPosition;
  Duration? _lastSoundPosition;

  AudioService() {
    _initializeAudioSession();
    _setupPlayerListeners();
  }

  Future<void> _initializeAudioSession() async {
    try {
      _session = await AudioSession.instance;
      await _session!.configure(const AudioSessionConfiguration(
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
        androidWillPauseWhenDucked: false,
      ));
    } catch (e) {
      print("Error initializing audio session: $e");
    }
  }

  void _setupPlayerListeners() {
    // Listeners para o player de música
    _musicPlayer.playerStateStream.listen((state) {
      _isMusicPlaying = state.playing;
    });

    // Listeners para o player de sons
    _soundPlayer.playerStateStream.listen((state) {
      _isSoundPlaying = state.playing;
    });
  }

  // Métodos para música principal
  Future<void> loadMusic(String url) async {
    try {
      _currentMusicUrl = url;
      if (url.startsWith('assets/')) {
        await _musicPlayer.setAsset(url);
      } else {
        await _musicPlayer.setUrl(url);
      }
    } catch (e) {
      print("Error loading music: $e");
      rethrow;
    }
  }

  Future<void> playMusic() async {
    try {
      // Se é a mesma URL e temos uma posição salva, resume da posição
      if (_lastMusicPosition != null && _currentMusicUrl != null) {
        await _musicPlayer.seek(_lastMusicPosition!);
        _lastMusicPosition = null;
      }
      await _musicPlayer.play();
    } catch (e) {
      print("Error playing music: $e");
    }
  }

  void pauseMusic() {
    _lastMusicPosition = _musicPlayer.position;
    _musicPlayer.pause();
  }

  void stopMusic() {
    _musicPlayer.stop();
    _lastMusicPosition = null;
    _currentMusicUrl = null;
  }

  Future<void> resumeMusic() async {
    if (_lastMusicPosition != null) {
      await _musicPlayer.seek(_lastMusicPosition!);
      _lastMusicPosition = null;
    }
    await _musicPlayer.play();
  }

  // Métodos para sons ambientes/efeitos
  Future<void> loadSound(String url) async {
    try {
      _currentSoundUrl = url;
      if (url.startsWith('assets/')) {
        await _soundPlayer.setAsset(url);
      } else {
        await _soundPlayer.setUrl(url);
      }
    } catch (e) {
      print("Error loading sound: $e");
      rethrow;
    }
  }

  Future<void> playSound() async {
    try {
      // Configurar para loop se for um som ambiente
      await _soundPlayer.setLoopMode(LoopMode.one);
      await _soundPlayer.play();
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  void pauseSound() {
    _lastSoundPosition = _soundPlayer.position;
    _soundPlayer.pause();
  }

  void stopSound() {
    _soundPlayer.stop();
    _lastSoundPosition = null;
    _currentSoundUrl = null;
  }

  Future<void> resumeSound() async {
    if (_lastSoundPosition != null) {
      await _soundPlayer.seek(_lastSoundPosition!);
      _lastSoundPosition = null;
    }
    await _soundPlayer.play();
  }

  // Métodos de mixagem
  Future<void> playMix(String musicUrl, String soundUrl) async {
    try {
      // Carrega e toca a música principal
      await loadMusic(musicUrl);
      await playMusic();
      
      // Carrega e toca o som ambiente
      await loadSound(soundUrl);
      await playSound();
    } catch (e) {
      print("Error playing mix: $e");
    }
  }

  void pauseMix() {
    pauseMusic();
    pauseSound();
  }

  void resumeMix() {
    resumeMusic();
    resumeSound();
  }

  void stopMix() {
    stopMusic();
    stopSound();
  }

  // Controle de volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
  }

  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    await _soundPlayer.setVolume(_soundVolume);
  }

  Future<void> setMasterVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume * clampedVolume);
    await _soundPlayer.setVolume(_soundVolume * clampedVolume);
  }

  // Seek apenas para música principal
  Future<void> seek(Duration position) async {
    await _musicPlayer.seek(position);
  }

  // Getters para streams (apenas música principal para UI)
  Stream<Duration> get positionStream => _musicPlayer.positionStream;
  Stream<Duration?> get durationStream => _musicPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _musicPlayer.playerStateStream;

  // Getters para estado
  bool get isMusicPlaying => _isMusicPlaying;
  bool get isSoundPlaying => _isSoundPlaying;
  bool get isMixPlaying => _isMusicPlaying && _isSoundPlaying;
  
  double get musicVolume => _musicVolume;
  double get soundVolume => _soundVolume;

  // Método legado para compatibilidade
  Future<void> load(String url) async {
    await loadMusic(url);
  }

  Future<void> play() async {
    await playMusic();
  }

  void pause() {
    pauseMusic();
  }

  void stop() {
    stopMusic();
  }

  void resume() {
    resumeMusic();
  }

  Future<void> setVolume(double value) async {
    await setMusicVolume(value);
  }

  void dispose() {
    _musicPlayer.dispose();
    _soundPlayer.dispose();
  }
}

