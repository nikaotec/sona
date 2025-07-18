import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sona/model/mix_model.dart';
import 'package:sona/model/audio_model.dart';

class MixManagerProvider extends ChangeNotifier {
  List<MixModel> _mixes = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<MixModel> get mixes => List.unmodifiable(_mixes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMixes => _mixes.isNotEmpty;
  int get mixCount => _mixes.length;

  // Chave para persistência
  static const String _storageKey = 'user_mixes';

  // Inicialização
  Future<void> initialize() async {
    await loadMixes();
  }

  // Carregar mixes do armazenamento local
  Future<void> loadMixes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final mixesJson = prefs.getString(_storageKey);

      if (mixesJson != null) {
        final List<dynamic> mixesList = json.decode(mixesJson);
        _mixes = mixesList
            .map((mixMap) => MixModel.fromMap(mixMap))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar mixes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Salvar mixes no armazenamento local
  Future<void> _saveMixes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mixesJson = json.encode(_mixes.map((mix) => mix.toMap()).toList());
      await prefs.setString(_storageKey, mixesJson);
    } catch (e) {
      _error = 'Erro ao salvar mixes: $e';
      notifyListeners();
    }
  }

  // Adicionar novo mix
  Future<void> addMix(MixModel mix) async {
    try {
      _mixes.add(mix);
      await _saveMixes();
      HapticFeedback.mediumImpact();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao adicionar mix: $e';
      notifyListeners();
    }
  }

  // Criar novo mix vazio
  Future<MixModel> createNewMix(String name, {String? description}) async {
    final mix = MixModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      audios: [],
      createdAt: DateTime.now(),
      description: description,
    );

    await addMix(mix);
    return mix;
  }

  // Remover mix
  Future<void> removeMix(String id) async {
    try {
      _mixes.removeWhere((mix) => mix.id == id);
      await _saveMixes();
      HapticFeedback.mediumImpact();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover mix: $e';
      notifyListeners();
    }
  }

  // Atualizar mix existente
  Future<void> updateMix(MixModel updatedMix) async {
    try {
      final index = _mixes.indexWhere((mix) => mix.id == updatedMix.id);
      if (index != -1) {
        _mixes[index] = updatedMix;
        await _saveMixes();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar mix: $e';
      notifyListeners();
    }
  }

  // Obter mix por ID
  MixModel? getById(String id) {
    try {
      return _mixes.firstWhere((mix) => mix.id == id);
    } catch (e) {
      return null;
    }
  }

  // Adicionar/remover áudio de um mix
  Future<void> toggleAudioInMix(String mixId, AudioModel audio) async {
    try {
      final mix = getById(mixId);
      if (mix == null) return;

      List<AudioModel> updatedAudios = List.from(mix.audios);

      if (mix.containsAudio(audio)) {
        // Remover áudio
        updatedAudios.removeWhere((a) => a.id == audio.id);
      } else {
        // Adicionar áudio
        updatedAudios.add(audio);
      }

      final updatedMix = mix.copyWith(audios: updatedAudios);
      await updateMix(updatedMix);
      HapticFeedback.lightImpact();
    } catch (e) {
      _error = 'Erro ao modificar mix: $e';
      notifyListeners();
    }
  }

  // Adicionar áudio a um mix específico
  Future<void> addAudioToMix(String mixId, AudioModel audio) async {
    try {
      final mix = getById(mixId);
      if (mix == null) return;

      if (!mix.containsAudio(audio)) {
        final updatedAudios = List<AudioModel>.from(mix.audios)..add(audio);
        final updatedMix = mix.copyWith(audios: updatedAudios);
        await updateMix(updatedMix);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _error = 'Erro ao adicionar áudio ao mix: $e';
      notifyListeners();
    }
  }

  // Remover áudio de um mix específico
  Future<void> removeAudioFromMix(String mixId, AudioModel audio) async {
    try {
      final mix = getById(mixId);
      if (mix == null) return;

      final updatedAudios = List<AudioModel>.from(mix.audios)
        ..removeWhere((a) => a.id == audio.id);
      final updatedMix = mix.copyWith(audios: updatedAudios);
      await updateMix(updatedMix);
      HapticFeedback.lightImpact();
    } catch (e) {
      _error = 'Erro ao remover áudio do mix: $e';
      notifyListeners();
    }
  }

  // Reordenar áudios em um mix
  Future<void> reorderAudiosInMix(String mixId, int oldIndex, int newIndex) async {
    try {
      final mix = getById(mixId);
      if (mix == null) return;

      final updatedAudios = List<AudioModel>.from(mix.audios);
      
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      
      final audio = updatedAudios.removeAt(oldIndex);
      updatedAudios.insert(newIndex, audio);

      final updatedMix = mix.copyWith(audios: updatedAudios);
      await updateMix(updatedMix);
      HapticFeedback.selectionClick();
    } catch (e) {
      _error = 'Erro ao reordenar áudios: $e';
      notifyListeners();
    }
  }

  // Atualizar última reprodução
  Future<void> updateLastPlayed(String mixId) async {
    try {
      final mix = getById(mixId);
      if (mix == null) return;

      final updatedMix = mix.copyWith(lastPlayedAt: DateTime.now());
      await updateMix(updatedMix);
    } catch (e) {
      _error = 'Erro ao atualizar última reprodução: $e';
      notifyListeners();
    }
  }

  // Obter mixes recentes (ordenados por última reprodução)
  List<MixModel> get recentMixes {
    final mixesWithLastPlayed = _mixes
        .where((mix) => mix.lastPlayedAt != null)
        .toList();
    
    mixesWithLastPlayed.sort((a, b) => 
        b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
    
    return mixesWithLastPlayed.take(5).toList();
  }

  // Obter mixes favoritos (com mais de 3 reproduções ou criados recentemente)
  List<MixModel> get favoriteMixes {
    return _mixes
        .where((mix) => mix.audios.isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Verificar se um áudio está em algum mix
  List<MixModel> getMixesContainingAudio(AudioModel audio) {
    return _mixes
        .where((mix) => mix.containsAudio(audio))
        .toList();
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Duplicar mix
  Future<MixModel> duplicateMix(String mixId, String newName) async {
    try {
      final originalMix = getById(mixId);
      if (originalMix == null) {
        throw Exception('Mix não encontrado');
      }

      final duplicatedMix = MixModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: newName,
        audios: List.from(originalMix.audios),
        createdAt: DateTime.now(),
        description: originalMix.description,
      );

      await addMix(duplicatedMix);
      return duplicatedMix;
    } catch (e) {
      _error = 'Erro ao duplicar mix: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Estatísticas
  Map<String, dynamic> get statistics {
    final totalTracks = _mixes.fold<int>(0, (sum, mix) => sum + mix.trackCount);
    final totalDuration = _mixes.fold<Duration>(
      Duration.zero,
      (sum, mix) => sum + mix.totalDuration,
    );

    return {
      'totalMixes': _mixes.length,
      'totalTracks': totalTracks,
      'totalDuration': totalDuration,
      'averageTracksPerMix': _mixes.isNotEmpty ? totalTracks / _mixes.length : 0,
    };
  }
}

