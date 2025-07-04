import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:sona/model/audio_model.dart';

class MusicRepositoryService {
  static const String _localAssetsPath = 'assets/music/';
  String? _remoteRepositoryUrl;
  
  // Cache para evitar múltiplas requisições
  Map<String, List<AudioModel>> _categoryCache = {};
  
  // Configurar URL do repositório remoto
  void setRemoteRepository(String url) {
    _remoteRepositoryUrl = url;
    _categoryCache.clear(); // Limpar cache quando mudar repositório
  }
  
  // Obter músicas de uma categoria específica
  Future<List<AudioModel>> getMusicsByCategory(String category) async {
    // Verificar cache primeiro
    if (_categoryCache.containsKey(category)) {
      return _categoryCache[category]!;
    }
    
    List<AudioModel> localMusics = await _getLocalMusicsByCategory(category);
    List<AudioModel> remoteMusics = await _getRemoteMusicsByCategory(category);
    
    // Combinar músicas locais e remotas
    List<AudioModel> allMusics = [...localMusics, ...remoteMusics];
    
    // Armazenar no cache
    _categoryCache[category] = allMusics;
    
    return allMusics;
  }
  
  // Obter músicas locais dos assets
  Future<List<AudioModel>> _getLocalMusicsByCategory(String category) async {
    try {
      // Tentar carregar um arquivo de manifesto local se existir
      String manifestContent = await rootBundle.loadString('assets/music/manifest.json');
      Map<String, dynamic> manifest = json.decode(manifestContent);
      
      List<AudioModel> musics = [];
      
      if (manifest.containsKey(category)) {
        List<dynamic> categoryMusics = manifest[category];
        
        for (var musicData in categoryMusics) {
          musics.add(AudioModel(
            id: musicData['id'],
            title: musicData['title'],
            url: '$_localAssetsPath${musicData['file']}',
            category: category,
            duration: Duration(seconds: musicData['duration'] ?? 0),
            isPremium: musicData['isPremium'] ?? false,
          ));
        }
      }
      
      return musics;
    } catch (e) {
      // Se não houver manifesto, retornar músicas hardcoded baseadas na categoria
      return _getHardcodedLocalMusics(category);
    }
  }
  
  // Músicas locais hardcoded como fallback
  List<AudioModel> _getHardcodedLocalMusics(String category) {
    switch (category) {
      case 'Binaural Beats':
        return [
          AudioModel(
            id: 'local_bb1',
            title: 'Delta Waves 4Hz (Local)',
            url: 'assets/music/bineural/binaural-beats_delta_440_440-5hz-48565.mp3',
            category: 'Binaural Beats',
            duration: const Duration(minutes: 30),
            isPremium: false,
          ),
        ];
      case 'Nature Sounds':
        return [
          // Adicione aqui músicas locais de Nature Sounds se houver
        ];
      default:
        return [];
    }
  }
  
  // Obter músicas do repositório remoto
  Future<List<AudioModel>> _getRemoteMusicsByCategory(String category) async {
    if (_remoteRepositoryUrl == null) {
      return [];
    }
    
    try {
      // Fazer requisição para o repositório remoto
      final response = await http.get(
        Uri.parse('$_remoteRepositoryUrl/api/music/category/$category'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> musicsData = data['musics'] ?? [];
        
        return musicsData.map((musicData) {
          return AudioModel(
            id: musicData['id'],
            title: musicData['title'],
            url: musicData['url'],
            category: category,
            duration: Duration(seconds: musicData['duration'] ?? 0),
            isPremium: musicData['isPremium'] ?? false,
          );
        }).toList();
      }
    } catch (e) {
      print('Erro ao carregar músicas remotas: $e');
    }
    
    return [];
  }
  
  // Obter todas as categorias disponíveis
  Future<List<String>> getAvailableCategories() async {
    Set<String> categories = {};
    
    // Adicionar categorias locais
    categories.addAll(_getLocalCategories());
    
    // Adicionar categorias remotas
    if (_remoteRepositoryUrl != null) {
      try {
        final response = await http.get(
          Uri.parse('$_remoteRepositoryUrl/api/categories'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          Map<String, dynamic> data = json.decode(response.body);
          List<dynamic> remoteCategories = data['categories'] ?? [];
          categories.addAll(remoteCategories.cast<String>());
        }
      } catch (e) {
        print('Erro ao carregar categorias remotas: $e');
      }
    }
    
    return categories.toList();
  }
  
  // Categorias locais hardcoded
  List<String> _getLocalCategories() {
    return [
      'Binaural Beats',
      'Nature Sounds',
      'White Noise / Pink / Brown',
      'Guided Meditations',
      'Sleep',
    ];
  }
  
  // Limpar cache
  void clearCache() {
    _categoryCache.clear();
  }
  
  // Verificar se uma música está disponível localmente
  Future<bool> isMusicLocal(String url) async {
    return url.startsWith('assets/');
  }
  
  // Obter informações de uma música específica
  Future<AudioModel?> getMusicById(String id) async {
    // Procurar em todas as categorias
    for (String category in _getLocalCategories()) {
      List<AudioModel> musics = await getMusicsByCategory(category);
      for (AudioModel music in musics) {
        if (music.id == id) {
          return music;
        }
      }
    }
    return null;
  }
  
  // Sincronizar com repositório remoto
  Future<void> syncWithRemoteRepository() async {
    if (_remoteRepositoryUrl == null) return;
    
    try {
      // Limpar cache para forçar nova busca
      clearCache();
      
      // Recarregar todas as categorias
      List<String> categories = await getAvailableCategories();
      for (String category in categories) {
        await getMusicsByCategory(category);
      }
      
      print('Sincronização com repositório remoto concluída');
    } catch (e) {
      print('Erro na sincronização: $e');
    }
  }
}

