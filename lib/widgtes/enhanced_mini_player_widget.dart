import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sona/widgtes/mix_control_widget.dart';

/// Mini player aprimorado com suporte para mix de áudios
class EnhancedMiniPlayerWidget extends StatefulWidget {
  final bool showOnlyWhenPlaying;
  final EdgeInsets margin;

  const EnhancedMiniPlayerWidget({
    super.key,
    this.showOnlyWhenPlaying = true,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  State<EnhancedMiniPlayerWidget> createState() => _EnhancedMiniPlayerWidgetState();
}

class _EnhancedMiniPlayerWidgetState extends State<EnhancedMiniPlayerWidget> {
  bool _showMixControls = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedAudioProvider>(
      builder: (context, audioProvider, child) {
        // Verifica se deve mostrar o mini player
        final shouldShow = !widget.showOnlyWhenPlaying || 
                          audioProvider.currentAudio != null ||
                          audioProvider.hasMixActive;

        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: widget.margin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Controles de mix (se ativo e visível)
              if (_showMixControls && audioProvider.hasMixActive)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: MixControlWidget(
                    onClose: () {
                      setState(() {
                        _showMixControls = false;
                      });
                    },
                  ),
                ).animate().slideY(begin: 0.3, end: 0).fadeIn(),

              // Mini player principal
              _buildMainMiniPlayer(audioProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainMiniPlayer(EnhancedAudioProvider audioProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Informações do áudio atual e controles principais
          _buildMainControls(audioProvider),
          
          // Barra de progresso
          if (audioProvider.currentAudio != null)
            _buildProgressBar(audioProvider),
          
          // Indicador de mix e controles adicionais
          if (audioProvider.hasMixActive)
            _buildMixIndicator(audioProvider),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0).fadeIn();
  }

  Widget _buildMainControls(EnhancedAudioProvider audioProvider) {
    return Row(
      children: [
        // Artwork/Ícone
        GestureDetector(
          onTap: () {
            if (audioProvider.currentAudio != null) {
              context.go('/player');
            }
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              audioProvider.currentAudio != null 
                  ? Icons.music_note 
                  : Icons.queue_music,
              color: const Color(0xFF6C63FF),
              size: 24,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Informações do áudio
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (audioProvider.currentAudio != null) {
                context.go('/player');
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audioProvider.currentAudio?.title ?? 
                  (audioProvider.hasMixActive ? 'Mix Ativo' : 'Nenhum áudio'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  audioProvider.currentAudio?.category ?? 
                  (audioProvider.hasMixActive 
                      ? '${audioProvider.mixCount} áudio${audioProvider.mixCount > 1 ? 's' : ''}'
                      : 'Selecione uma música'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        
        // Controles de reprodução
        _buildPlaybackControls(audioProvider),
      ],
    );
  }

  Widget _buildPlaybackControls(EnhancedAudioProvider audioProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão de mix
        if (audioProvider.hasMixActive)
          IconButton(
            icon: Icon(
              _showMixControls ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF6C63FF),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showMixControls = !_showMixControls;
              });
            },
          ),
        
        // Botão play/pause principal
        if (audioProvider.currentAudio != null)
          Container(
            width: 36,
            height: 36,
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
                size: 18,
              ),
              onPressed: audioProvider.isLoading 
                  ? null 
                  : () {
                      audioProvider.toggleMainPlayPause(context);
                    },
            ),
          ),
        
        // Botão de próximo/parar
        IconButton(
          icon: const Icon(
            Icons.stop,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () {
            audioProvider.stopAll();
          },
        ),
      ],
    );
  }

  Widget _buildProgressBar(EnhancedAudioProvider audioProvider) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6C63FF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF6C63FF),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              trackHeight: 3,
              overlayShape: SliderComponentShape.noOverlay,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(audioProvider.currentPosition),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                Text(
                  _formatDuration(audioProvider.totalDuration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixIndicator(EnhancedAudioProvider audioProvider) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.queue_music,
            color: Color(0xFF6C63FF),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mix: ${audioProvider.mixCount} áudio${audioProvider.mixCount > 1 ? 's' : ''} ativo${audioProvider.mixCount > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showMixControls = !_showMixControls;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _showMixControls ? Icons.expand_less : Icons.tune,
                color: const Color(0xFF6C63FF),
                size: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3, end: 0);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
