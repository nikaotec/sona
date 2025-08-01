import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sona/model/audio_model.dart';

class SavedMix {
  final String id;
  final String name;
  final List<AudioModel> audios;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isFavorite;

  SavedMix({
    required this.id,
    required this.name,
    required this.audios,
    required this.createdAt,
    required this.lastModified,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'audios': audios.map((audio) => audio.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory SavedMix.fromJson(Map<String, dynamic> json) {
    return SavedMix(
      id: json['id'],
      name: json['name'],
      audios: (json['audios'] as List)
          .map((audioJson) => AudioModel.fromMap(audioJson))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  SavedMix copyWith({
    String? id,
    String? name,
    List<AudioModel>? audios,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isFavorite,
  }) {
    return SavedMix(
      id: id ?? this.id,
      name: name ?? this.name,
      audios: audios ?? this.audios,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class MixManagerProvider extends ChangeNotifier {
  static const String _savedMixesKey = 'saved_mixes';
  static const String _currentMixKey = 'current_mix_id';
  
  List<SavedMix> _savedMixes = [];
  String? _currentMixId;
  bool _isLoading = false;

  List<SavedMix> get savedMixes => List.unmodifiable(_savedMixes);
  String? get currentMixId => _currentMixId;
  bool get isLoading => _isLoading;
  
  SavedMix? get currentMix {
    if (_currentMixId == null) return null;
    try {
      return _savedMixes.firstWhere((mix) => mix.id == _currentMixId);
    } catch (e) {
      return null;
    }
  }

  List<SavedMix> get favoriteMixes => 
      _savedMixes.where((mix) => mix.isFavorite).toList();

  List<SavedMix> get recentMixes {
    final sortedMixes = List<SavedMix>.from(_savedMixes);
    sortedMixes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return sortedMixes.take(5).toList();
  }

  /// Inicializar o provider carregando dados salvos
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadSavedMixes();
      await _loadCurrentMixId();
    } catch (e) {
      debugPrint('Erro ao inicializar MixManagerProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carregar mixes salvos do SharedPreferences
  Future<void> _loadSavedMixes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMixesJson = prefs.getString(_savedMixesKey);
      
      if (savedMixesJson != null) {
        final List<dynamic> mixesList = json.decode(savedMixesJson);
        _savedMixes = mixesList
            .map((mixJson) => SavedMix.fromJson(mixJson))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar mixes salvos: $e');
      _savedMixes = [];
    }
  }

  /// Carregar ID do mix atual
  Future<void> _loadCurrentMixId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentMixId = prefs.getString(_currentMixKey);
    } catch (e) {
      debugPrint('Erro ao carregar mix atual: $e');
      _currentMixId = null;
    }
  }

  /// Salvar mixes no SharedPreferences
  Future<void> _saveMixes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mixesJson = json.encode(_savedMixes.map((mix) => mix.toJson()).toList());
      await prefs.setString(_savedMixesKey, mixesJson);
    } catch (e) {
      debugPrint('Erro ao salvar mixes: $e');
    }
  }

  /// Salvar ID do mix atual
  Future<void> _saveCurrentMixId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentMixId != null) {
        await prefs.setString(_currentMixKey, _currentMixId!);
      } else {
        await prefs.remove(_currentMixKey);
      }
    } catch (e) {
      debugPrint('Erro ao salvar mix atual: $e');
    }
  }

  /// Criar um novo mix
  Future<SavedMix> createMix({
    required String name,
    required List<AudioModel> audios,
    Map<String, double>? volumes,
    bool setAsCurrent = true,
  }) async {
    final now = DateTime.now();
    final newMix = SavedMix(
      id: _generateMixId(),
      name: name,
      audios: audios.map((audio) => audio.copyWith(volume: volumes?[audio.id] ?? 1.0)).toList(),
      createdAt: now,
      lastModified: now,
    );

    _savedMixes.add(newMix);
    
    if (setAsCurrent) {
      _currentMixId = newMix.id;
      await _saveCurrentMixId();
    }

    await _saveMixes();
    notifyListeners();

    return newMix;
  }

  /// Atualizar um mix existente
  Future<void> updateMix(String mixId, {
    String? name,
    List<AudioModel>? audios,
    bool? isFavorite,
  }) async {
    final mixIndex = _savedMixes.indexWhere((mix) => mix.id == mixId);
    if (mixIndex == -1) return;

    final currentMix = _savedMixes[mixIndex];
    final updatedMix = currentMix.copyWith(
      name: name,
      audios: audios,
      isFavorite: isFavorite,
      lastModified: DateTime.now(),
    );

    _savedMixes[mixIndex] = updatedMix;
    await _saveMixes();
    notifyListeners();
  }

  /// Deletar um mix
  Future<void> deleteMix(String mixId) async {
    _savedMixes.removeWhere((mix) => mix.id == mixId);
    
    if (_currentMixId == mixId) {
      _currentMixId = null;
      await _saveCurrentMixId();
    }

    await _saveMixes();
    notifyListeners();
  }

  /// Duplicar um mix
  Future<SavedMix> duplicateMix(String mixId, {String? newName}) async {
    final originalMix = _savedMixes.firstWhere((mix) => mix.id == mixId);
    
    final duplicatedMix = await createMix(
      name: newName ?? '${originalMix.name} (Cópia)',
      audios: originalMix.audios,
      setAsCurrent: false,
    );

    return duplicatedMix;
  }

  /// Definir mix como atual
  Future<void> setCurrentMix(String? mixId) async {
    _currentMixId = mixId;
    await _saveCurrentMixId();
    notifyListeners();
  }

  /// Alternar favorito
  Future<void> toggleFavorite(String mixId) async {
    final mixIndex = _savedMixes.indexWhere((mix) => mix.id == mixId);
    if (mixIndex == -1) return;

    final currentMix = _savedMixes[mixIndex];
    await updateMix(mixId, isFavorite: !currentMix.isFavorite);
  }

  /// Adicionar áudio a um mix específico
  Future<void> addAudioToMix(String mixId, AudioModel audio) async {
    final mixIndex = _savedMixes.indexWhere((mix) => mix.id == mixId);
    if (mixIndex == -1) return;

    final currentMix = _savedMixes[mixIndex];
    final updatedAudios = List<AudioModel>.from(currentMix.audios);
    
    // Verificar se o áudio já existe no mix
    if (!updatedAudios.any((existingAudio) => existingAudio.id == audio.id)) {
      updatedAudios.add(audio);
      await updateMix(mixId, audios: updatedAudios);
    }
  }

  /// Remover áudio de um mix específico
  Future<void> removeAudioFromMix(String mixId, String audioId) async {
    final mixIndex = _savedMixes.indexWhere((mix) => mix.id == mixId);
    if (mixIndex == -1) return;

    final currentMix = _savedMixes[mixIndex];
    final updatedAudios = currentMix.audios
        .where((audio) => audio.id != audioId)
        .toList();
    
    await updateMix(mixId, audios: updatedAudios);
  }

  /// Reordenar áudios em um mix
  Future<void> reorderAudiosInMix(String mixId, int oldIndex, int newIndex) async {
    final mixIndex = _savedMixes.indexWhere((mix) => mix.id == mixId);
    if (mixIndex == -1) return;

    final currentMix = _savedMixes[mixIndex];
    final updatedAudios = List<AudioModel>.from(currentMix.audios);
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = updatedAudios.removeAt(oldIndex);
    updatedAudios.insert(newIndex, item);
    
    await updateMix(mixId, audios: updatedAudios);
  }

  /// Buscar mixes por nome
  List<SavedMix> searchMixes(String query) {
    if (query.isEmpty) return _savedMixes;
    
    return _savedMixes.where((mix) =>
        mix.name.toLowerCase().contains(query.toLowerCase()) ||
        mix.audios.any((audio) =>
            audio.title.toLowerCase().contains(query.toLowerCase()) ||
            audio.category.toLowerCase().contains(query.toLowerCase())
        )
    ).toList();
  }

  /// Obter estatísticas dos mixes
  Map<String, dynamic> getMixStatistics() {
    final totalMixes = _savedMixes.length;
    final totalAudios = _savedMixes.fold<int>(
      0, 
      (sum, mix) => sum + mix.audios.length,
    );
    final favoriteMixesCount = favoriteMixes.length;
    
    final categoryCount = <String, int>{};
    for (final mix in _savedMixes) {
      for (final audio in mix.audios) {
        categoryCount[audio.category] = (categoryCount[audio.category] ?? 0) + 1;
      }
    }

    return {
      'totalMixes': totalMixes,
      'totalAudios': totalAudios,
      'favoriteMixes': favoriteMixesCount,
      'categoriesUsed': categoryCount.keys.length,
      'mostUsedCategory': categoryCount.isNotEmpty 
          ? categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  /// Gerar ID único para mix
  String _generateMixId() {
    return 'mix_${DateTime.now().millisecondsSinceEpoch}_${_savedMixes.length}';
  }

  /// Limpar todos os dados (para debug/reset)
  Future<void> clearAllData() async {
    _savedMixes.clear();
    _currentMixId = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedMixesKey);
    await prefs.remove(_currentMixKey);
    
    notifyListeners();
  }

  /// Exportar mixes para JSON (para backup)
  String exportMixesToJson() {
    return json.encode({
      'mixes': _savedMixes.map((mix) => mix.toJson()).toList(),
      'currentMixId': _currentMixId,
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Importar mixes de JSON (para restaurar backup)
  Future<void> importMixesFromJson(String jsonString) async {
    try {
      final data = json.decode(jsonString);
      final mixesList = data['mixes'] as List;
      
      _savedMixes = mixesList
          .map((mixJson) => SavedMix.fromJson(mixJson))
          .toList();
      
      _currentMixId = data['currentMixId'];
      
      await _saveMixes();
      await _saveCurrentMixId();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao importar mixes: $e');
      throw Exception('Formato de arquivo inválido');
    }
  }
}