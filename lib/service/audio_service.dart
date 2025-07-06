import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> load(String url) async {
    try {
      if (url.startsWith('assets/')) {
        await _player.setAsset(url);
      } else {
        await _player.setUrl(url);
      }
    } catch (e) {
      print("Error loading audio: $e");
      rethrow;
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  void pause() => _player.pause();
  void stop() => _player.stop();
  void resume() => _player.play();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> setVolume(double value) => _player.setVolume(value);

  Future<void> seek(Duration position) => _player.seek(position);
}


