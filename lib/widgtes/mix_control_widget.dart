import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Widget para controle de mix de múltiplos áudios
class MixControlWidget extends StatefulWidget {
  final bool showAsBottomSheet;
  final VoidCallback? onClose;

  const MixControlWidget({
    super.key,
    this.showAsBottomSheet = false,
    this.onClose,
  });

  @override
  State<MixControlWidget> createState() => _MixControlWidgetState();
}

class _MixControlWidgetState extends State<MixControlWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedAudioProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.hasMixActive) {
          return _buildEmptyMixState();
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: widget.showAsBottomSheet 
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(audioProvider),
              _buildMixList(audioProvider),
              _buildGlobalControls(audioProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(EnhancedAudioProvider audioProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF2A2A3E),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.queue_music,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mix Ativo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${audioProvider.mixCount} áudio${audioProvider.mixCount > 1 ? 's' : ''} tocando',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: widget.onClose,
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3, end: 0);
  }

  Widget _buildMixList(EnhancedAudioProvider audioProvider) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: audioProvider.activeMix.length,
        itemBuilder: (context, index) {
          final entry = audioProvider.activeMix.entries.elementAt(index);
          final playerId = entry.key;
          final audio = entry.value;
          final volume = audioProvider.mixVolumes[playerId] ?? 1.0;

          return _buildMixItem(audioProvider, playerId, audio, volume, index);
        },
      ),
    );
  }

  Widget _buildMixItem(
    EnhancedAudioProvider audioProvider,
    String playerId,
    AudioModel audio,
    double volume,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      audio.category,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () {
                  audioProvider.removeFromMix(audio.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.volume_up,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF6C63FF),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: const Color(0xFF6C63FF),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    trackHeight: 4,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      audioProvider.setMixAudioVolume(audio.id, value);
                    },
                  ),
                ),
              ),
              Text(
                '${(volume * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.3, end: 0);
  }

  Widget _buildGlobalControls(EnhancedAudioProvider audioProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFF2A2A3E),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                audioProvider.pauseMix();
              },
              icon: const Icon(Icons.pause, size: 18),
              label: const Text('Pausar Mix'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                audioProvider.resumeMix();
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Retomar Mix'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showClearMixDialog(audioProvider);
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Limpar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildEmptyMixState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: widget.showAsBottomSheet 
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.queue_music,
              color: Color(0xFF6C63FF),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum Mix Ativo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione múltiplos áudios para criar um mix personalizado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          if (widget.onClose != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onClose,
              child: const Text(
                'Fechar',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().scale();
  }

  void _showClearMixDialog(EnhancedAudioProvider audioProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Limpar Mix',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja remover todos os áudios do mix?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              audioProvider.clearMix();
              Navigator.pop(context);
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
}
