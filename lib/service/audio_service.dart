import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String url) async {
    try {
      if (url.startsWith('assets/')) {
        // It's an asset
        await _player.setAsset(url);
      } else {
        // It's a URL
        await _player.setUrl(url);
      }
      await _player.play();
    } catch (e) {
      // TODO: Consider more robust error handling or logging
      print("Error playing audio: $e");
      // Rethrow or handle as per app's error strategy
      rethrow;
    }
  }

  void pause() => _player.pause();
  void stop() => _player.stop();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> setVolume(double value) => _player.setVolume(value);

  Future<void> seek(Duration position) => _player.seek(position);
}
