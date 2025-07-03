import 'package:flutter/material.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/service/user_data_service.dart';

class UserDataProvider extends ChangeNotifier {
  final UserDataService _service = UserDataService();
  List<AudioModel> _favorites = [];

  List<AudioModel> get favorites => _favorites;

  Future<void> loadFavorites() async {
    _favorites = await _service.getFavorites();
    notifyListeners();
  }

  Future<void> toggleFavorite(AudioModel audio) async {
    final exists = _favorites.any((a) => a.id == audio.id);
    if (exists) {
      await _service.removeFromFavorites(audio.id);
      _favorites.removeWhere((a) => a.id == audio.id);
    } else {
      await _service.addToFavorites(audio);
      _favorites.add(audio);
    }
    notifyListeners();
  }

  Future<void> saveToHistory(AudioModel audio) async {
    await _service.addToHistory(audio);
  }
}
