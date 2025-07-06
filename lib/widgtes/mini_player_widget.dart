import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:sona/provider/video_ad_provider.dart';
import 'package:sona/model/audio_model.dart';

class MiniPlayerWidget extends StatefulWidget {
  final bool showOnlyWhenPlaying;
  final EdgeInsets? margin;
  final double? height;

  const MiniPlayerWidget({
    super.key,
    this.showOnlyWhenPlaying = true,
    this.margin,
    this.height,
  });

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePlayPause(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final videoAdProvider = Provider.of<VideoAdProvider>(context, listen: false);
    
    if (audioProvider.currentAudio == null) return;

    if (audioProvider.isPlaying) {
      // Se está tocando, apenas pausa
      audioProvider.pauseAudio();
    } else {
      // Se não está tocando, verifica se precisa mostrar anúncio
      videoAdProvider.showVideoAdIfNeeded(
        audioProvider.currentAudio!.id,
        onAdCompleted: () {
          audioProvider.resumeAudio();
        },
        onAdFailed: (error) {
          // Se falhar, toca a música mesmo assim
          audioProvider.resumeAudio();
        },
        onUserEarnedReward: () {
          // Usuário ganhou recompensa
        },
      );
    }
  }

  void _navigateToPlayer(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (audioProvider.currentAudio != null) {
      context.go('/player', extra: {
        'heroTag': 'mini_player_${audioProvider.currentAudio!.id}',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioProvider, VideoAdProvider>(
      builder: (context, audioProvider, videoAdProvider, child) {
        final currentAudio = audioProvider.currentAudio;
        final isPlaying = audioProvider.isPlaying;
        final isLoading = audioProvider.isLoading;
        final isShowingAd = videoAdProvider.isAdShowing;

        // Se não há áudio atual e deve mostrar apenas quando tocando, não exibe
        if (widget.showOnlyWhenPlaying && currentAudio == null) {
          if (_slideController.isCompleted) {
            _slideController.reverse();
          }
          return const SizedBox.shrink();
        }

        // Se há áudio, mostra o player
        if (currentAudio != null) {
          if (!_slideController.isCompleted) {
            _slideController.forward();
          }
          
          // Controla animação de pulse quando está tocando
          if (isPlaying && !_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          } else if (!isPlaying) {
            _pulseController.stop();
            _pulseController.reset();
          }

          return SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: widget.margin ?? const EdgeInsets.all(16),
              height: widget.height ?? 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2A3E), Color(0xFF3A3A4E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _navigateToPlayer(context),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Artwork/Ícone da música
                        Hero(
                          tag: 'mini_player_${currentAudio.id}',
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isPlaying ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPlaying 
                                        ? [const Color(0xFF6B73FF), const Color(0xFF9644FF)]
                                        : [const Color(0xFF4A4A5E), const Color(0xFF5A5A6E)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Informações da música
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentAudio.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentAudio.category,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Botão de play/pause
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B73FF),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: isShowingAd ? null : () => _handlePlayPause(context),
                              child: Center(
                                child: isShowingAd
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// Widget compacto para uso em AppBars
class CompactMiniPlayer extends StatelessWidget {
  const CompactMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final currentAudio = audioProvider.currentAudio;
        final isPlaying = audioProvider.isPlaying;

        if (currentAudio == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                context.go('/player', extra: {
                  'heroTag': 'compact_player_${currentAudio.id}',
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: const Color(0xFF6B73FF),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentAudio.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget para exibir progresso da música
class MiniPlayerProgress extends StatelessWidget {
  const MiniPlayerProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final currentPosition = audioProvider.currentPosition;
        final totalDuration = audioProvider.totalDuration;

        if (totalDuration.inMilliseconds == 0) {
          return const SizedBox.shrink();
        }

        final progress = currentPosition.inMilliseconds / totalDuration.inMilliseconds;

        return Container(
          height: 2,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6B73FF),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      },
    );
  }
}

