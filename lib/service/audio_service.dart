import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  void pause() => _player.pause();
  void stop() => _player.stop();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> setVolume(double value) => _player.setVolume(value);
}
