import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/model/onboarding_model.dart';
import 'package:sona/service/user_data_service.dart';

class UserDataProvider extends ChangeNotifier {
  late UserDataService _service;
  List<AudioModel> _favorites = [];
  OnboardingData? _onboardingData;
  String? _preferredCategory;

  List<AudioModel> get favorites => _favorites;
  OnboardingData? get onboardingData => _onboardingData;
  String? get preferredCategory => _preferredCategory;

  UserDataProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _service = UserDataService(user.uid);
    } else {
      debugPrint('Erro: usuário não está logado');
      // Trate redirecionamento ou exiba mensagem
    }
  }

  // Mapeamento de estilos de som para categorias
  final Map<String, String> _styleToCategory = {
    'Sons da natureza (chuva, mar, vento)': 'Natureza',
    'Batidas suaves (binaural, ASMR)': 'Binaural',
    'Música instrumental relaxante': 'Instrumental',
    'Voz suave guiando a meditação': 'Meditação',
    'Não tenho certeza ainda': 'Relaxamento', // Categoria padrão
  };

  Future<void> loadUserData() async {
    await loadFavorites();
    await loadOnboardingData();
  }

  Future<void> loadFavorites() async {
    try {
      _favorites = await _service.getFavorites();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar favoritos: $e');
    }
  }

  Future<void> loadOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingJson = prefs.getString('onboarding_data');

      if (onboardingJson != null) {
        final Map<String, dynamic> data = json.decode(onboardingJson);
        _onboardingData = OnboardingData.fromJson(data);

        // Determinar categoria preferida baseada no estilo de som
        if (_onboardingData?.estilo != null) {
          _preferredCategory =
              _styleToCategory[_onboardingData!.estilo] ?? 'Relaxamento';
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados de onboarding: $e');
    }
  }

  Future<void> saveOnboardingData(OnboardingData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data.toJson());
      await prefs.setString('onboarding_data', jsonString);

      _onboardingData = data;

      // Determinar categoria preferida baseada no estilo de som
      if (data.estilo != null) {
        _preferredCategory = _styleToCategory[data.estilo!] ?? 'Relaxamento';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar dados de onboarding: $e');
    }
  }

  Future<void> toggleFavorite(AudioModel audio) async {
    try {
      final exists = _favorites.any((a) => a.id == audio.id);
      if (exists) {
        await _service.removeFromFavorites(audio.id);
        _favorites.removeWhere((a) => a.id == audio.id);
      } else {
        await _service.addToFavorites(audio);
        _favorites.add(audio);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao alternar favorito: $e');
    }
  }

  Future<void> saveToHistory(AudioModel audio) async {
    try {
      await _service.addToHistory(audio);
    } catch (e) {
      debugPrint('Erro ao salvar no histórico: $e');
    }
  }

  // Método para obter recomendação personalizada baseada no onboarding
  String getPersonalizedRecommendation() {
    if (_onboardingData == null)
      return 'Explore nossas categorias de relaxamento';

    final objetivo = _onboardingData!.objetivo ?? '';
    final humor = _onboardingData!.humor ?? '';
    final estilo = _onboardingData!.estilo ?? '';

    if (objetivo.contains('Dormir melhor')) {
      return 'Sons relaxantes para uma noite tranquila';
    } else if (objetivo.contains('Reduzir ansiedade')) {
      return 'Meditações e sons calmantes para reduzir a ansiedade';
    } else if (objetivo.contains('Focar')) {
      return 'Sons binaurais para melhorar o foco e concentração';
    } else if (objetivo.contains('Relaxar')) {
      return 'Músicas e sons da natureza para relaxamento profundo';
    } else if (objetivo.contains('Meditar')) {
      return 'Meditações guiadas para sua prática diária';
    }

    return 'Conteúdo personalizado baseado em suas preferências';
  }

  // Método para obter ícone baseado na categoria preferida
  IconData getPreferredCategoryIcon() {
    switch (_preferredCategory) {
      case 'Natureza':
        return Icons.nature;
      case 'Binaural':
        return Icons.headphones;
      case 'Instrumental':
        return Icons.music_note;
      case 'Meditação':
        return Icons.self_improvement;
      default:
        return Icons.spa;
    }
  }

  // Método para limpar dados de onboarding (útil para testes)
  Future<void> clearOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_data');
      _onboardingData = null;
      _preferredCategory = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao limpar dados de onboarding: $e');
    }
  }

  // Método para verificar se o usuário completou o onboarding
  bool get hasCompletedOnboarding => _onboardingData != null;

  // Método para obter estatísticas do usuário
  Map<String, dynamic> getUserStats() {
    return {
      'favoritesCount': _favorites.length,
      'hasOnboarding': hasCompletedOnboarding,
      'preferredCategory': _preferredCategory,
      'objetivo': _onboardingData?.objetivo,
      'humor': _onboardingData?.humor,
      'estilo': _onboardingData?.estilo,
      'horario': _onboardingData?.horario,
    };
  }
}
