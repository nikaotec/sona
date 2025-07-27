import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/model/mix_track_model.dart' show MixTrack;
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/components/expectromi/audio_visualizer/visualizer_manager.dart';

class MixPlayerScreen extends StatefulWidget {
  const MixPlayerScreen({super.key});

  @override
  State<MixPlayerScreen> createState() => _MixPlayerScreenState();
}

class _MixPlayerScreenState extends State<MixPlayerScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isExpanded = false;
  String _mixName = 'Meu Mix';
  final TextEditingController _mixNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    
    _mixNameController.text = _mixName;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _mixNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedAudioProvider>(
      builder: (context, audioProvider, child) {
        final mixTracks = audioProvider.mixTracks;
        
        if (mixTracks.isEmpty) {
          return _buildEmptyMixScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D3748),
                  Color(0xFF1A1A2E),
                  Color(0xFF0F0F1E),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header com controles principais
                  _buildHeader(audioProvider),
                  
                  // Visualizador central
                  if (!_isExpanded) ...[
                    _buildCentralVisualizer(audioProvider),
                  ],
                  
                  // Lista de faixas do mix
                  Expanded(
                    child: _buildMixTracksList(audioProvider, mixTracks),
                  ),
                  
                  // Controles inferiores
                  _buildBottomControls(audioProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyMixScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D3748),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header simples
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/categories'),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Mix Player',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              // Conteúdo vazio
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.queue_music,
                          size: 64,
                          color: Colors.white54,
                        ),
                      ).animate().scale(curve: Curves.elasticOut),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        'Nenhuma música no mix',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Adicione músicas ao seu mix para começar\na criar sua experiência sonora personalizada',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      
                      const SizedBox(height: 32),
                      
                      ElevatedButton.icon(
                        onPressed: () => context.go('/categories'),
                        icon: const Icon(Icons.explore),
                        label: const Text('Explorar Músicas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B73FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).scale(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(EnhancedAudioProvider audioProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Barra superior
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/categories'),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                
                Expanded(
                  child: GestureDetector(
                    onTap: _showMixNameDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _mixName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                  color: const Color(0xFF2A2A3E),
                  onSelected: (value) => _handleMenuAction(value, audioProvider),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'save',
                      child: Row(
                        children: [
                          Icon(Icons.save, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text('Salvar Mix', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Limpar Tudo', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.share, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text('Compartilhar', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações do mix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMixInfo(
                  icon: Icons.queue_music,
                  label: 'Faixas',
                  value: '${audioProvider.mixTracks.length}',
                ),
                _buildMixInfo(
                  icon: Icons.volume_up,
                  label: 'Volume Master',
                  value: '${(audioProvider.masterVolume * 100).round()}%',
                ),
                _buildMixInfo(
                  icon: audioProvider.isAnyMixPlaying ? Icons.play_circle : Icons.pause_circle,
                  label: 'Status',
                  value: audioProvider.isAnyMixPlaying ? 'Tocando' : 'Pausado',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMixInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6B73FF),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCentralVisualizer(EnhancedAudioProvider audioProvider) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: VisualizerManager(
          isPlaying: audioProvider.isAnyMixPlaying,
          size: 160,
          primaryColor: const Color(0xFF6B73FF),
          secondaryColor: const Color(0xFF9644FF),
          allowTypeChange: true,
        ),
      ),
    ).animate().scale(delay: 400.ms, curve: Curves.elasticOut);
  }

  Widget _buildMixTracksList(EnhancedAudioProvider audioProvider, List<MixTrack> mixTracks) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header da lista
            Row(
              children: [
                const Text(
                  'Faixas do Mix',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Lista de faixas
            Expanded(
              child: ListView.builder(
                itemCount: mixTracks.length,
                itemBuilder: (context, index) {
                  final track = mixTracks[index];
                  return _buildMixTrackCard(track, index, audioProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMixTrackCard(MixTrack track, int index, EnhancedAudioProvider audioProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: track.isPlaying 
              ? const Color(0xFF6B73FF).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
        boxShadow: track.isPlaying ? [
          BoxShadow(
            color: const Color(0xFF6B73FF).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        children: [
          // Header da faixa
          Row(
            children: [
              // Ícone de categoria
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B73FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(track.audio.category),
                  color: const Color(0xFF6B73FF),
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Informações da música
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.audio.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.audio.category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Controles da faixa
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão play/pause
                  IconButton(
                    onPressed: () => audioProvider.toggleMixTrack(track.audio.id),
                    icon: Icon(
                      track.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: const Color(0xFF6B73FF),
                    ),
                  ),
                  
                  // Botão remover
                  IconButton(
                    onPressed: () => _showRemoveTrackDialog(track, audioProvider),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Controle de volume
          Row(
            children: [
              const Icon(
                Icons.volume_down,
                color: Colors.white54,
                size: 20,
              ),
              
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF6B73FF),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: const Color(0xFF6B73FF),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    trackHeight: 4,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: track.volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      audioProvider.setMixTrackVolume(track.audio.id, value);
                      HapticFeedback.lightImpact();
                    },
                  ),
                ),
              ),
              
              const Icon(
                Icons.volume_up,
                color: Colors.white54,
                size: 20,
              ),
              
              const SizedBox(width: 8),
              
              Text(
                '${(track.volume * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.3, end: 0);
  }

  Widget _buildBottomControls(EnhancedAudioProvider audioProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Volume master
          Row(
            children: [
              const Icon(
                Icons.volume_up,
                color: Color(0xFF6B73FF),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Volume Master',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(audioProvider.masterVolume * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6B73FF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF6B73FF),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10,
              ),
              trackHeight: 6,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: audioProvider.masterVolume,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                audioProvider.setMasterVolume(value);
                HapticFeedback.lightImpact();
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Controles principais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pausar tudo
              _buildControlButton(
                icon: Icons.pause,
                label: 'Pausar Tudo',
                onPressed: () {
                  audioProvider.pauseAll();
                  HapticFeedback.mediumImpact();
                },
                color: Colors.orange,
              ),
              
              // Play/Pause geral
              _buildControlButton(
                icon: audioProvider.isAnyMixPlaying ? Icons.pause : Icons.play_arrow,
                label: audioProvider.isAnyMixPlaying ? 'Pausar' : 'Tocar',
                onPressed: () {
                  if (audioProvider.isAnyMixPlaying) {
                    audioProvider.pauseAll();
                  } else {
                    audioProvider.playAll();
                  }
                  HapticFeedback.mediumImpact();
                },
                color: const Color(0xFF6B73FF),
                isPrimary: true,
              ),
              
              // Parar tudo
              _buildControlButton(
                icon: Icons.stop,
                label: 'Parar Tudo',
                onPressed: () {
                  audioProvider.stopAll();
                  HapticFeedback.heavyImpact();
                },
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Container(
          width: isPrimary ? 64 : 56,
          height: isPrimary ? 64 : 56,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: isPrimary ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: onPressed,
              child: Icon(
                icon,
                color: Colors.white,
                size: isPrimary ? 32 : 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'natureza':
        return Icons.nature;
      case 'binaural':
        return Icons.graphic_eq;
      case 'instrumental':
        return Icons.music_note;
      case 'meditação':
        return Icons.self_improvement;
      case 'relaxamento':
        return Icons.spa;
      case 'white noise':
        return Icons.blur_on;
      case 'sleep':
        return Icons.nightlight_round;
      default:
        return Icons.music_note;
    }
  }

  void _showMixNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Nome do Mix',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _mixNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Digite o nome do mix',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6B73FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _mixName = _mixNameController.text.isNotEmpty 
                    ? _mixNameController.text 
                    : 'Meu Mix';
              });
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showRemoveTrackDialog(MixTrack track, EnhancedAudioProvider audioProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Remover Faixa',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja remover "${track.audio.title}" do mix?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              audioProvider.removeFromMix(track.audio.id);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${track.audio.title} removido do mix'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Remover',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, EnhancedAudioProvider audioProvider) {
    switch (action) {
      case 'save':
        _saveMix(audioProvider);
        break;
      case 'clear':
        _clearMix(audioProvider);
        break;
      case 'export':
        _exportMix(audioProvider);
        break;
    }
  }

  void _saveMix(EnhancedAudioProvider audioProvider) {
    // TODO: Implementar salvamento do mix
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mix "$_mixName" salvo com sucesso!'),
        backgroundColor: const Color(0xFF6B73FF),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearMix(EnhancedAudioProvider audioProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Limpar Mix',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Isso removerá todas as faixas do mix atual. Deseja continuar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              audioProvider.clearMix();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mix limpo com sucesso'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Limpar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _exportMix(EnhancedAudioProvider audioProvider) {
    // TODO: Implementar compartilhamento do mix
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhamento em breve!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
