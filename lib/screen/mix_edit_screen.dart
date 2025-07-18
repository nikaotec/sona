import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sona/components/banner_ad_widget.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/model/mix_model.dart';
import 'package:sona/provider/mix_manager_provider.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:sona/provider/subscription_provider.dart';

class MixEditScreen extends StatefulWidget {
  final String mixId;

  const MixEditScreen({
    super.key,
    required this.mixId,
  });

  @override
  State<MixEditScreen> createState() => _MixEditScreenState();
}

class _MixEditScreenState extends State<MixEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMixData();
    });
  }

  void _loadMixData() {
    final mixManager = Provider.of<MixManagerProvider>(context, listen: false);
    final mix = mixManager.getById(widget.mixId);
    
    if (mix != null) {
      _nameController.text = mix.name;
      _descriptionController.text = mix.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Editar Mix',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: const Color(0xFF6C63FF),
            ),
            onPressed: _toggleEditMode,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2A2A3E),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Duplicar Mix', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Excluir Mix', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<MixManagerProvider, SubscriptionProvider>(
        builder: (context, mixManager, subscriptionProvider, child) {
          final mix = mixManager.getById(widget.mixId);
          
          if (mix == null) {
            return const Center(
              child: Text(
                'Mix não encontrado',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informações do Mix
                      _buildMixInfo(mix),
                      
                      const SizedBox(height: 32),
                      
                      // Estatísticas
                      _buildStatistics(mix),
                      
                      const SizedBox(height: 32),
                      
                      // Controles de Reprodução
                      _buildPlaybackControls(mix),
                      
                      const SizedBox(height: 32),
                      
                      // Lista de Músicas
                      _buildMusicList(mix, mixManager),
                      
                      const SizedBox(height: 24),
                      
                      // Botão Adicionar Música
                      _buildAddMusicButton(),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Banner de Anúncio (apenas para usuários não premium)
              if (!subscriptionProvider.hasActiveSubscription)
                const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMixInfo(MixModel mix) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9644FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.queue_music,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing)
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nome do Mix',
                          hintStyle: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      Text(
                        mix.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Criado em ${_formatDate(mix.createdAt)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_isEditing || mix.description?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            if (_isEditing)
              TextField(
                controller: _descriptionController,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Descrição do mix (opcional)',
                  hintStyle: TextStyle(color: Colors.white60),
                ),
                maxLines: 3,
              )
            else if (mix.description?.isNotEmpty == true)
              Text(
                mix.description!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3, end: 0);
  }

  Widget _buildStatistics(MixModel mix) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.music_note,
            label: 'Faixas',
            value: mix.trackCount.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time,
            label: 'Duração',
            value: _formatDuration(mix.totalDuration),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.play_circle,
            label: 'Última',
            value: mix.lastPlayedAt != null 
                ? _formatDate(mix.lastPlayedAt!)
                : 'Nunca',
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 24),
          const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildPlaybackControls(MixModel mix) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final isPlaying = audioProvider.isPlaying;
        final canPlay = mix.audios.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.shuffle,
                label: 'Aleatório',
                onPressed: canPlay ? () => _playMixShuffled(mix) : null,
              ),
              _buildControlButton(
                icon: isPlaying ? Icons.pause_circle : Icons.play_circle,
                label: isPlaying ? 'Pausar' : 'Tocar',
                onPressed: canPlay ? () => _togglePlayback(mix) : null,
                isPrimary: true,
              ),
              _buildControlButton(
                icon: Icons.repeat,
                label: 'Repetir',
                onPressed: canPlay ? () => _playMixLoop(mix) : null,
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isPrimary 
                ? const Color(0xFF6C63FF) 
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(28),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: Colors.white,
              size: isPrimary ? 32 : 24,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMusicList(MixModel mix, MixManagerProvider mixManager) {
    if (mix.audios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.music_off,
              color: Colors.white.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma música adicionada',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão abaixo para adicionar músicas ao seu mix',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Músicas no Mix',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${mix.audios.length} ${mix.audios.length == 1 ? 'música' : 'músicas'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mix.audios.length,
          onReorder: (oldIndex, newIndex) {
            mixManager.reorderAudiosInMix(widget.mixId, oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final audio = mix.audios[index];
            return _buildMusicItem(audio, index, mixManager);
          },
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildMusicItem(
    AudioModel audio,
    int index,
    MixManagerProvider mixManager,
  ) {
    return Container(
      key: ValueKey(audio.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A4E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.music_note,
                color: Color(0xFF6C63FF),
                size: 24,
              ),
            ),
          ],
        ),
        title: Text(
          audio.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              audio.category,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            Text(
              _formatDuration(audio.duration),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Color(0xFF6C63FF)),
              onPressed: () => _playAudio(audio),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeAudioFromMix(audio, mixManager),
            ),
            const Icon(Icons.drag_handle, color: Colors.white54),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.3, end: 0);
  }

  Widget _buildAddMusicButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addMusic,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Música'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0);
  }

  void _toggleEditMode() {
    if (_isEditing) {
      _saveMixInfo();
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveMixInfo() {
    final mixManager = Provider.of<MixManagerProvider>(context, listen: false);
    final mix = mixManager.getById(widget.mixId);
    
    if (mix != null) {
      final updatedMix = mix.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );
      
      mixManager.updateMix(updatedMix);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mix atualizado com sucesso!'),
          backgroundColor: Color(0xFF6C63FF),
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'duplicate':
        _duplicateMix();
        break;
      case 'delete':
        _deleteMix();
        break;
    }
  }

  void _duplicateMix() async {
    final mixManager = Provider.of<MixManagerProvider>(context, listen: false);
    final mix = mixManager.getById(widget.mixId);
    
    if (mix != null) {
      try {
        await mixManager.duplicateMix(widget.mixId, '${mix.name} (Cópia)');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mix duplicado com sucesso!'),
              backgroundColor: Color(0xFF6C63FF),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao duplicar mix: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deleteMix() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Excluir Mix',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja excluir este mix? Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDeleteMix();
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMix() async {
    final mixManager = Provider.of<MixManagerProvider>(context, listen: false);
    await mixManager.removeMix(widget.mixId);
    
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mix excluído com sucesso!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _togglePlayback(MixModel mix) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final mixManager = Provider.of<MixManagerProvider>(context, listen: false);
    
    if (audioProvider.isPlaying) {
      audioProvider.pauseMix();
    } else {
      audioProvider.playMix(mix.audios);
      mixManager.updateLastPlayed(widget.mixId);
    }
  }

  void _playMixShuffled(MixModel mix) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final mixManager = Provider.of<MixManagerProvider>(context, listen: false);
    
    final shuffledAudios = List<AudioModel>.from(mix.audios)..shuffle();
    audioProvider.playMix(shuffledAudios);
    mixManager.updateLastPlayed(widget.mixId);
  }

  void _playMixLoop(MixModel mix) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final mixManager = Provider.of<MixManagerProvider>(context, listen: false);
    
    audioProvider.playMix(mix.audios, loop: true);
    mixManager.updateLastPlayed(widget.mixId);
  }

  void _playAudio(AudioModel audio) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.playAudio(context, audio);
  }

  void _removeAudioFromMix(AudioModel audio, MixManagerProvider mixManager) {
    mixManager.removeAudioFromMix(widget.mixId, audio);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${audio.title} removido do mix'),
        backgroundColor: const Color(0xFF6C63FF),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            mixManager.addAudioToMix(widget.mixId, audio);
          },
        ),
      ),
    );
  }

  void _addMusic() {
    context.go('/category-music-list', extra: {
      'categoryName': 'Todas as Músicas',
      'audios': <AudioModel>[], // Lista vazia para mostrar todas
      'mixId': widget.mixId, // Passar ID do mix para adicionar músicas
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

