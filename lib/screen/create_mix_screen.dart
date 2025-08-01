import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/mix_manager_provider.dart';
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:sona/widgtes/mini_player_widget.dart';
import 'package:sona/widgets/draggable_audio_item.dart';
import 'package:sona/widgets/mix_drop_zone.dart';

class CreateMixScreen extends StatefulWidget {
  const CreateMixScreen({super.key});

  @override
  State<CreateMixScreen> createState() => _CreateMixScreenState();
}

class _CreateMixScreenState extends State<CreateMixScreen> {
  final TextEditingController _mixNameController = TextEditingController();
  final List<AudioModel> _selectedAudios = [];
  String _selectedCategory = 'Todos';
  bool _isCreatingMix = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Todos', 'audios': []},
    {
      'name': 'Natureza',
      'audios': [
        AudioModel(
          id: '3',
          title: 'Tranquil Pond',
          url: 'https://example.com/audio1.mp3',
          category: 'Natureza',
          duration: const Duration(minutes: 10),
          isPremium: false,
        ),
        AudioModel(
          id: '4',
          title: 'Ocean Waves',
          url: 'https://example.com/ocean.mp3',
          category: 'Natureza',
          duration: const Duration(minutes: 15),
          isPremium: true,
        ),
      ]
    },
    {
      'name': 'Binaural',
      'audios': [
        AudioModel(
          id: '1',
          title: 'Binaural Beats Delta',
          url: 'assets/music/bineural/binaural-beats_delta_440_440-5hz-48565.mp3',
          category: 'Binaural',
          duration: const Duration(minutes: 5),
          isPremium: false,
        ),
        AudioModel(
          id: '2',
          title: 'Alpha Waves Focus',
          url: 'https://example.com/alpha.mp3',
          category: 'Binaural',
          duration: const Duration(minutes: 8),
          isPremium: true,
        ),
      ]
    },
    {
      'name': 'Instrumental',
      'audios': [
        AudioModel(
          id: '13',
          title: 'Piano Relaxante',
          url: 'assets/music/instrumental/piano.mp3',
          category: 'Instrumental',
          duration: const Duration(minutes: 12),
          isPremium: false,
        ),
        AudioModel(
          id: '14',
          title: 'Violino Suave',
          url: 'https://example.com/violin.mp3',
          category: 'Instrumental',
          duration: const Duration(minutes: 8),
          isPremium: true,
        ),
      ]
    },
    {
      'name': 'Meditação',
      'audios': [
        AudioModel(
          id: '7',
          title: 'Body Scan',
          url: 'https://example.com/audio2.mp3',
          category: 'Meditação',
          duration: const Duration(minutes: 10),
          isPremium: true,
        ),
        AudioModel(
          id: '8',
          title: 'Breathing Exercise',
          url: 'https://example.com/breathing.mp3',
          category: 'Meditação',
          duration: const Duration(minutes: 5),
          isPremium: false,
        ),
      ]
    },
    {
      'name': 'Relaxamento',
      'audios': [
        AudioModel(
          id: '15',
          title: 'Relaxamento Profundo',
          url: 'https://example.com/deep_relax.mp3',
          category: 'Relaxamento',
          duration: const Duration(minutes: 20),
          isPremium: false,
        ),
        AudioModel(
          id: '16',
          title: 'Spa Sounds',
          url: 'https://example.com/spa.mp3',
          category: 'Relaxamento',
          duration: const Duration(minutes: 15),
          isPremium: true,
        ),
      ]
    },
    {
      'name': 'White Noise',
      'audios': [
        AudioModel(
          id: '5',
          title: 'White Noise',
          url: 'https://example.com/white_noise.mp3',
          category: 'White Noise',
          duration: const Duration(minutes: 30),
          isPremium: false,
        ),
        AudioModel(
          id: '6',
          title: 'Pink Noise',
          url: 'https://example.com/pink_noise.mp3',
          category: 'White Noise',
          duration: const Duration(minutes: 30),
          isPremium: true,
        ),
      ]
    },
    {
      'name': 'Sleep',
      'audios': [
        AudioModel(
          id: '9',
          title: 'Deep Sleep Mix',
          url: 'https://example.com/sleep.mp3',
          category: 'Sleep',
          duration: const Duration(hours: 1),
          isPremium: true,
        ),
        AudioModel(
          id: '10',
          title: 'Lullaby',
          url: 'https://example.com/lullaby.mp3',
          category: 'Sleep',
          duration: const Duration(minutes: 20),
          isPremium: false,
        ),
      ]
    },
  ];

  @override
  void dispose() {
    _mixNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/categories');
            }
          },
        ),
        title: const Text(
          'Criar Mix',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedAudios.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _isCreatingMix ? null : _createMix,
                child: _isCreatingMix
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Salvar',
                        style: TextStyle(
                          color: Color(0xFF6B73FF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header com nome do mix - responsivo
            Container(
              padding: EdgeInsets.fromLTRB(
                16, 
                8, 
                16, 
                keyboardHeight > 0 ? 8 : 16
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nome do Mix',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _mixNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ex: Relaxamento Noturno',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF2A2A3E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.3, end: 0),

            // Mix Drop Zone - ajustado para responsividade
            if (keyboardHeight == 0) // Ocultar quando teclado estiver aberto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MixDropZone(
                  onAudioDropped: _addToMix,
                  currentMix: _selectedAudios,
                  isExpanded: false,
                  onTapToPlay: _selectedAudios.isNotEmpty ? _openMixPlayer : null,
                ),
              ).animate().fadeIn(delay: 100.ms).scale(),

            // Filtro de categorias - responsivo
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final categoryName = category['name'] as String;
                  final isSelected = categoryName == _selectedCategory;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = categoryName;
                        });
                      },
                      backgroundColor: const Color(0xFF2A2A3E),
                      selectedColor: const Color(0xFF6B73FF),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF6B73FF) : Colors.transparent,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3, end: 0),

            // Lista de áudios disponíveis - responsivo
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Sons Disponíveis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (keyboardHeight == 0) // Ocultar hint quando teclado estiver aberto
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B73FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Arraste para o mix',
                              style: TextStyle(
                                color: Color(0xFF6B73FF),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: keyboardHeight > 0 ? 0 : 80, // Espaço para mini player
                        ),
                        itemCount: _getFilteredAudios().length,
                        itemBuilder: (context, index) {
                          final audio = _getFilteredAudios()[index];
                          final isSelected = _selectedAudios.contains(audio);
                          final isInMix = _selectedAudios.any((a) => a.id == audio.id);
                          
                          return DraggableAudioItem(
                            audio: audio,
                            index: index,
                            isSelected: isSelected,
                            isInMix: isInMix,
                            onTap: () => _toggleAudioSelection(audio),
                            onPreview: () => _previewAudio(audio),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Mini Player - ocultar quando teclado estiver aberto
      bottomSheet: keyboardHeight == 0 
          ? const MiniPlayerWidget(
              showOnlyWhenPlaying: false,
              margin: EdgeInsets.all(16),
            )
          : null,
    );
  }

  void _addToMix(AudioModel audio) {
    if (!_selectedAudios.any((a) => a.id == audio.id)) {
      setState(() {
        _selectedAudios.add(audio.copyWith(volume: 0.7)); // Volume padrão
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${audio.title} adicionado ao mix"),
          backgroundColor: const Color(0xFF6B73FF),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _toggleAudioSelection(AudioModel audio) {
    setState(() {
      if (_selectedAudios.any((a) => a.id == audio.id)) {
        _selectedAudios.removeWhere((a) => a.id == audio.id);
      } else {
        _selectedAudios.add(audio.copyWith(volume: 0.7));
      }
    });
  }

  List<AudioModel> _getFilteredAudios() {
    if (_selectedCategory == 'Todos') {
      // Retornar todos os áudios de todas as categorias
      List<AudioModel> allAudios = [];
      for (var category in _categories) {
        if (category['name'] != 'Todos') {
          allAudios.addAll(category['audios'] as List<AudioModel>);
        }
      }
      return allAudios;
    }
    
    // Encontrar a categoria selecionada e retornar seus áudios
    final selectedCategoryData = _categories.firstWhere(
      (category) => category['name'] == _selectedCategory,
      orElse: () => {'name': '', 'audios': <AudioModel>[]},
    );
    
    return selectedCategoryData['audios'] as List<AudioModel>;
  }

  List<AudioModel> _getSampleAudios() {
    return [
      AudioModel(
        id: '1',
        title: 'Chuva Suave',
        category: 'Chuva',
        url: 'assets/audio/rain_soft.mp3',
        duration: const Duration(minutes: 30),
      ),
      AudioModel(
        id: '2',
        title: 'Ondas do Mar',
        category: 'Oceano',
        url: 'assets/audio/ocean_waves.mp3',
        duration: const Duration(minutes: 45),
      ),
      AudioModel(
        id: '3',
        title: 'Floresta Tropical',
        category: 'Floresta',
        url: 'assets/audio/forest_tropical.mp3',
        duration: const Duration(minutes: 60),
      ),
      AudioModel(
        id: '4',
        title: 'Meditação Guiada',
        category: 'Meditação',
        url: 'assets/audio/meditation_guided.mp3',
        duration: const Duration(minutes: 20),
      ),
      AudioModel(
        id: '5',
        title: 'Piano Relaxante',
        category: 'Instrumental',
        url: 'assets/audio/piano_relaxing.mp3',
        duration: const Duration(minutes: 35),
      ),
    ];
  }

  void _previewAudio(AudioModel audio) {
    // Implementar preview do áudio
    final audioProvider = Provider.of<EnhancedAudioProvider>(context, listen: false);
    audioProvider.playAudio(context, audio);
  }

  void _openMixPlayer() {
    if (_selectedAudios.isEmpty) return;
    
    // Criar um mix temporário para testar
    final mixManager = Provider.of<MixManagerProvider>(context, listen: false);
    final audioProvider = Provider.of<EnhancedAudioProvider>(context, listen: false);
    
    // Carregar o mix temporário no audio provider
    audioProvider.loadMix(_selectedAudios);
    
    // Navegar para o mix player com callback de retorno
    context.push('/mix-player').then((_) {
      // Quando voltar do mix player, permanece na tela de criação
      // Não precisa fazer nada especial, apenas continua na tela atual
    });
  }

  void _createMix() async {
    if (_mixNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um nome para o mix'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAudios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um som para o mix'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingMix = true;
    });

    try {
      final mixManager = Provider.of<MixManagerProvider>(context, listen: false);
      
      // Criar o mix com os volumes personalizados
      await mixManager.createMix(
        name: _mixNameController.text.trim(),
        audios: _selectedAudios,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mix criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar para category_screen para mostrar o novo mix
        context.go('/categories');
      }
    } catch (e) {
      debugPrint('Erro ao criar mix: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar mix: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingMix = false;
        });
      }
    }
  }
}
