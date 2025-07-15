import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sona/widgtes/mix_control_widget.dart';

/// Tela de player aprimorada com suporte para mix de áudios
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showMixControls = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedAudioProvider>(
      builder: (context, audioProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: SafeArea(
            child: Column(
              children: [
                // AppBar customizada
                _buildCustomAppBar(audioProvider),
                
                // Conteúdo principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Artwork principal
                        _buildMainArtwork(audioProvider),
                        
                        const SizedBox(height: 32),
                        
                        // Informações da música
                        _buildTrackInfo(audioProvider),
                        
                        const SizedBox(height: 32),
                        
                        // Controles de reprodução
                        _buildPlaybackControls(audioProvider),
                        
                        const SizedBox(height: 24),
                        
                        // Barra de progresso
                        _buildProgressSection(audioProvider),
                        
                        const SizedBox(height: 32),
                        
                        // Controles de mix
                        if (audioProvider.hasMixActive)
                          _buildMixSection(audioProvider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomAppBar(EnhancedAudioProvider audioProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
            onPressed: () => context.pop(),
          ).animate().fadeIn().scale(),
          
          const Spacer(),
          
          const Text(
            'Player',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 100.ms),
          
          const Spacer(),
          
          // Botão de mix
          if (audioProvider.hasMixActive)
            IconButton(
              icon: Icon(
                _showMixControls ? Icons.queue_music : Icons.queue_music_outlined,
                color: _showMixControls ? const Color(0xFF6C63FF) : Colors.white,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _showMixControls = !_showMixControls;
                });
              },
            ).animate().fadeIn(delay: 200.ms).scale()
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainArtwork(EnhancedAudioProvider audioProvider) {
    return Hero(
      tag: 'player_artwork',
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.3),
              const Color(0xFF9644FF).withOpacity(0.3),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Main icon
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    audioProvider.currentAudio != null 
                        ? Icons.music_note 
                        : Icons.queue_music,
                    color: Colors.white,
                    size: 80,
                  ).animate().scale(curve: Curves.elasticOut),
                  
                  if (audioProvider.hasMixActive) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Mix: ${audioProvider.mixCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(curve: Curves.easeOutBack);
  }

  Widget _buildTrackInfo(EnhancedAudioProvider audioProvider) {
    return Column(
      children: [
        Text(
          audioProvider.currentAudio?.title ?? 'Nenhuma música selecionada',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
        
        const SizedBox(height: 8),
        
        Text(
          audioProvider.currentAudio?.category ?? 
          (audioProvider.hasMixActive 
              ? '${audioProvider.mixCount} áudio${audioProvider.mixCount > 1 ? 's' : ''} no mix'
              : 'Selecione uma música para começar'),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildPlaybackControls(EnhancedAudioProvider audioProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Botão anterior (placeholder)
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 32),
          onPressed: () {
            // Implementação futura para música anterior
          },
        ).animate().fadeIn(delay: 400.ms).scale(),
        
        // Botão play/pause principal
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFF6C63FF),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              audioProvider.isLoading
                  ? Icons.hourglass_empty
                  : (audioProvider.isPlaying ? Icons.pause : Icons.play_arrow),
              color: Colors.white,
              size: 32,
            ),
            onPressed: audioProvider.isLoading || audioProvider.currentAudio == null
                ? null
                : () {
                    audioProvider.toggleMainPlayPause(context);
                  },
          ),
        ).animate().fadeIn(delay: 500.ms).scale(curve: Curves.elasticOut),
        
        // Botão próximo (placeholder)
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white70, size: 32),
          onPressed: () {
            // Implementação futura para próxima música
          },
        ).animate().fadeIn(delay: 600.ms).scale(),
      ],
    );
  }

  Widget _buildProgressSection(EnhancedAudioProvider audioProvider) {
    if (audioProvider.currentAudio == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF6C63FF),
            inactiveTrackColor: Colors.white24,
            thumbColor: const Color(0xFF6C63FF),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
            ),
            trackHeight: 4,
            overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
          ),
          child: Slider(
            value: audioProvider.currentPosition.inSeconds.toDouble().clamp(
              0.0, 
              audioProvider.totalDuration.inSeconds.toDouble()
            ),
            max: audioProvider.totalDuration.inSeconds.toDouble() > 0 
                ? audioProvider.totalDuration.inSeconds.toDouble() 
                : 1.0,
            onChanged: (value) {
              audioProvider.seekMainAudio(Duration(seconds: value.toInt()));
            },
          ),
        ),
        
        const SizedBox(height: 8),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(audioProvider.currentPosition),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatDuration(audioProvider.totalDuration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildMixSection(EnhancedAudioProvider audioProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Controles de Mix',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Switch(
              value: _showMixControls,
              onChanged: (value) {
                setState(() {
                  _showMixControls = value;
                });
              },
              activeColor: const Color(0xFF6C63FF),
            ),
          ],
        ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3, end: 0),
        
        const SizedBox(height: 16),
        
        if (_showMixControls)
          MixControlWidget(
            onClose: () {
              setState(() {
                _showMixControls = false;
              });
            },
          ).animate().slideY(begin: 0.3, end: 0).fadeIn(),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
