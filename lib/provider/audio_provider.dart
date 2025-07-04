import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/audio_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _service = AudioService();
  AudioModel? _currentAudio;
  bool _isPlaying = false;

  AudioModel? get currentAudio => _currentAudio;
  bool get isPlaying => _isPlaying;

  void playAudio(BuildContext context, AudioModel audio) async {
    final paywall = Provider.of<PaywallProvider>(context, listen: false);
    await paywall.loadData();
    bool allowed = await paywall.registerPlay();
    if (!allowed) {
      Navigator.of(context).pushNamed('/paywall');
      return;
    }

    _currentAudio = audio;
    await _service.play(audio.url);
    _isPlaying = true;
    notifyListeners();
  }

  void pauseAudio() {
    _service.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void stopAudio() {
    _service.stop();
    _isPlaying = false;
    _currentAudio = null;
    notifyListeners();
  }
}
