import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/components/expectromi/audio_visualizer/visualizer_manager.dart';
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:sona/components/banner_ad_widget.dart';
import 'package:sona/provider/paywall_provider.dart';

class PlayerScreen extends StatefulWidget {
  final String? heroTag;

  const PlayerScreen({super.key, this.heroTag});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedAudioProvider>(
      builder: (context, audioProvider, child) {
        final paywallProvider = Provider.of<PaywallProvider>(context);
        final audio = audioProvider.currentAudio;

        if (audio == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(
              child: Text(
                'Nenhum áudio selecionado',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final screenHeight = MediaQuery.of(context).size.height;
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
                  // Header animado
                  _buildAnimatedHeader(screenWidth, audioProvider, audio),

                  // Banner de anúncio para usuários não premium
                  if (!paywallProvider.isPremium)
                    const BannerAdWidget()
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: -0.3, end: 0),

                  // Visualizador de áudio
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: VisualizerManager(
                        isPlaying: audioProvider.isPlaying,
                        size: screenWidth * 0.8,
                        primaryColor: const Color(0xFF6B73FF),
                        secondaryColor: const Color(0xFF9644FF),
                        allowTypeChange: true,
                      ).animate().scale(delay: 400.ms, duration: 800.ms, curve: Curves.elasticOut),
                    ),
                  ),

                  // Informações da música e controles animados
                  Expanded(
                    flex: 2,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildAnimatedControls(
                        screenWidth,
                        screenHeight,
                        audioProvider,
                        audio,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeader(double screenWidth, EnhancedAudioProvider audioProvider, dynamic audio) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Row(
        children: [
          AnimatedBackButton(
            onPressed: () => context.go('/categories'),
          ),
          Expanded(
            child: Text(
              'MindWave',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.5, end: 0),
          ),
          // Botão para adicionar/remover do mix
          AnimatedMixButton(
            isInMix: audioProvider.isInMix(audio.id),
            onPressed: () {
              if (audioProvider.isInMix(audio.id)) {
                audioProvider.removeFromMix(audio.id);
                _showAddToMixSnackBar(false);
              } else {
                audioProvider.addToMix(audio);
                _showAddToMixSnackBar(true);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddToMixSnackBar(bool isAdded) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAdded ? 'Música adicionada ao mix!' : 'Música removida do mix!',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isAdded ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildAnimatedControls(
    double screenWidth,
    double screenHeight,
    EnhancedAudioProvider audioProvider,
    dynamic audio,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Categoria
          Text(
            audio.category,
            style: TextStyle(
              color: Colors.white70,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w400,
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),

          // Título da música
          Text(
            audio.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.08,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),

          // Barra de progresso animada
          _buildAnimatedProgressBar(screenWidth, screenHeight, audioProvider),

          // Controles de reprodução animados
          _buildAnimatedPlayControls(screenWidth, audioProvider),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgressBar(
    double screenWidth,
    double screenHeight,
    EnhancedAudioProvider audioProvider,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6B73FF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF6B73FF),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: screenWidth * 0.02,
              ),
              trackHeight: screenHeight * 0.005,
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
        ),

        // Tempos
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(audioProvider.currentPosition),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: screenWidth * 0.035,
                ),
              ),
              Text(
                '-${_formatDuration(audioProvider.totalDuration - audioProvider.currentPosition)}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildAnimatedPlayControls(
    double screenWidth,
    EnhancedAudioProvider audioProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botão anterior
        AnimatedControlButton(
          icon: Icons.skip_previous,
          size: screenWidth * 0.1,
          onPressed: () {
            // TODO: Implementar música anterior
          },
          delay: 900.ms,
        ),

        SizedBox(width: screenWidth * 0.05),

        // Botão play/pause principal com pulsação
        AnimatedBuilder(
          animation: audioProvider.isPlaying ? AlwaysStoppedAnimation(1.0) : AlwaysStoppedAnimation(0.0), // Animação condicional
          builder: (context, child) {
            return Transform.scale(
              scale: audioProvider.isPlaying ? 1.05 : 1.0, // Pequena escala quando tocando
              child: Container(
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: audioProvider.isLoading
                    ? const CircularProgressIndicator(
                        color: Color(0xFF1A1A2E),
                      )
                    : IconButton(
                        icon: Icon(
                          audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: screenWidth * 0.1,
                          color: const Color(0xFF1A1A2E),
                        ),
                        onPressed: () {
                          audioProvider.toggleMainPlayPause(context);
                        },
                      ),
              ),
            );
          },
        ).animate().scale(delay: 1000.ms, duration: 600.ms, curve: Curves.elasticOut),

        SizedBox(width: screenWidth * 0.05),

        // Botão próximo
        AnimatedControlButton(
          icon: Icons.skip_next,
          size: screenWidth * 0.1,
          onPressed: () {
            // TODO: Implementar próxima música
          },
          delay: 1100.ms,
        ),
      ],
    );
  }
}

// Widget personalizado para botão de voltar animado
class AnimatedBackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedBackButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<AnimatedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.3, end: 0);
  }
}

// Widget personalizado para botão de mix animado
class AnimatedMixButton extends StatefulWidget {
  final bool isInMix;
  final VoidCallback onPressed;

  const AnimatedMixButton({
    super.key,
    required this.isInMix,
    required this.onPressed,
  });

  @override
  State<AnimatedMixButton> createState() => _AnimatedMixButtonState();
}

class _AnimatedMixButtonState extends State<AnimatedMixButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isInMix
                    ? const Color(0xFF6B73FF).withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isInMix
                      ? const Color(0xFF6B73FF)
                      : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Icon(
                widget.isInMix ? Icons.playlist_add_check : Icons.playlist_add,
                color: widget.isInMix
                    ? const Color(0xFF6B73FF)
                    : Colors.white,
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.3, end: 0);
  }
}

// Widget personalizado para botões de controle animados
class AnimatedControlButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressed;
  final Duration delay;

  const AnimatedControlButton({
    super.key,
    required this.icon,
    required this.size,
    required this.onPressed,
    required this.delay,
  });

  @override
  State<AnimatedControlButton> createState() => _AnimatedControlButtonState();
}

class _AnimatedControlButtonState extends State<AnimatedControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Icon(
                widget.icon,
                size: widget.size,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: widget.delay).scale(curve: Curves.elasticOut);
  }
}

