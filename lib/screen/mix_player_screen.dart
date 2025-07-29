import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:sona/model/mix_track_model.dart';
import 'package:sona/components/expectromi/audio_visualizer/visualizer_manager.dart';

class MixPlayerScreen extends StatefulWidget {
  const MixPlayerScreen({super.key});

  @override
  State<MixPlayerScreen> createState() => _MixPlayerScreenState();
}

class _MixPlayerScreenState extends State<MixPlayerScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedAudioProvider>(
      builder: (context, audioProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A5568),
                  Color(0xFF2D3748),
                  Color(0xFF1A1A2E),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, audioProvider),
                  Expanded(
                    child: audioProvider.mixTracks.isEmpty
                        ? _buildEmptyMixState()
                        : _buildMixContent(audioProvider, screenWidth),
                  ),
                  _buildGlobalControls(audioProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, EnhancedAudioProvider audioProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              'Meu Mix (${audioProvider.mixCount})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: Implementar opções do mix (salvar, compartilhar, etc.)
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMixState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.queue_music, color: Colors.white54, size: 80),
          const SizedBox(height: 20),
          const Text(
            'Seu mix está vazio',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Adicione músicas da tela do player para criar seu mix personalizado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => context.go('/categories'),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Adicionar Músicas', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B73FF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixContent(EnhancedAudioProvider audioProvider, double screenWidth) {
    return Column(
      children: [
        // Visualizador de áudio para o mix
        SizedBox(
          height: screenWidth * 0.6,
          child: VisualizerManager(
            isPlaying: audioProvider.isAnyMixPlaying,
            size: screenWidth * 0.6,
            primaryColor: const Color(0xFF6B73FF),
            secondaryColor: const Color(0xFF9644FF),
            allowTypeChange: true,
          ).animate().scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: audioProvider.mixTracks.length,
            itemBuilder: (context, index) {
              final mixTrack = audioProvider.mixTracks[index];
              return _buildMixTrackItem(mixTrack, audioProvider, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMixTrackItem(MixTrackModel mixTrack, EnhancedAudioProvider audioProvider, int index) {
    return Animate(
      effects: [FadeEffect(delay: (100 * index).ms), SlideEffect(begin: const Offset(0.1, 0), end: Offset.zero)],
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    mixTrack.isPlaying ? Icons.volume_up : Icons.volume_mute,
                    color: mixTrack.isPlaying ? const Color(0xFF6B73FF) : Colors.white54,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mixTrack.audio.title,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          mixTrack.audio.category,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      audioProvider.removeFromMix(mixTrack.id);
                    },
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF6B73FF),
                  inactiveTrackColor: Colors.white24,
                  thumbColor: const Color(0xFF6B73FF),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight: 4,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: mixTrack.volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    audioProvider.setMixAudioVolume(mixTrack.id, value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalControls(EnhancedAudioProvider audioProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGlobalControlButton(
                icon: Icons.pause,
                label: 'Pausar Tudo',
                onPressed: () => audioProvider.pauseMix(),
              ),
              _buildGlobalControlButton(
                icon: Icons.play_arrow,
                label: 'Tocar Tudo',
                onPressed: () => audioProvider.resumeMix(),
              ),
              _buildGlobalControlButton(
                icon: Icons.stop,
                label: 'Parar Tudo',
                onPressed: () => audioProvider.clearMix(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF9644FF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF9644FF),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: audioProvider.mixVolumes.values.isNotEmpty 
                  ? audioProvider.mixVolumes.values.reduce((a, b) => a + b) / audioProvider.mixVolumes.length
                  : 0.0, // Média dos volumes ou 0 se vazio
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                // Implementar controle de volume master para o mix
                // Isso pode ser feito iterando sobre os players do mix e ajustando o volume
                // ou adicionando um método setGlobalMixVolume no EnhancedAudioProvider
              },
            ),
          ),
          const Text(
            'Volume Master do Mix',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildGlobalControlButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label, // Unique tag for each button
          onPressed: onPressed,
          backgroundColor: const Color(0xFF2A2A3E),
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

