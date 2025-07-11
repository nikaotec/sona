import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/components/circular_music_visualizer.dart';
import 'package:sona/components/visualizer_style_manager.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:sona/components/banner_ad_widget.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/model/audio_model.dart';

class PlayerScreen extends StatefulWidget {
  final String? heroTag;

  const PlayerScreen({super.key, this.heroTag});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Variáveis para o visualizador
  VisualizerStyleConfig? _currentVisualizerStyle;
  bool _showVisualizer = true;
  
  // Variáveis para mixagem
  bool _showMixControls = false;
  List<AudioModel> _availableSounds = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvailableSounds();
  }

  void _initializeAnimations() {
    // Controlador para rotação do ícone de música
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    // Controlador para pulsação do botão play
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Controlador para slide dos controles
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Iniciar animações
    _slideController.forward();
    
    // Escutar mudanças no provider de áudio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      if (audioProvider.isPlaying) {
        _rotationController.repeat();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _loadAvailableSounds() {
    // Sons ambiente disponíveis para mixagem
    _availableSounds = [
      AudioModel(
        id: 'rain',
        title: 'Chuva',
        category: 'Nature Sounds',
        url: 'assets/music/nature/rain.mp3',
        duration: const Duration(minutes: 60),
        isPremium: false,
      ),
      AudioModel(
        id: 'ocean',
        title: 'Oceano',
        category: 'Nature Sounds',
        url: 'assets/music/nature/ocean.mp3',
        duration: const Duration(minutes: 60),
        isPremium: false,
      ),
      AudioModel(
        id: 'forest',
        title: 'Floresta',
        category: 'Nature Sounds',
        url: 'assets/music/nature/forest.mp3',
        duration: const Duration(minutes: 60),
        isPremium: false,
      ),
      AudioModel(
        id: 'fire',
        title: 'Lareira',
        category: 'Nature Sounds',
        url: 'assets/music/nature/fire.mp3',
        duration: const Duration(minutes: 60),
        isPremium: false,
      ),
    ];
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  void _generateNewVisualizerStyle(dynamic audio) {
    if (audio != null) {
      _currentVisualizerStyle = VisualizerStyleManager.getStyleForMusic(
        category: audio.category,
        title: audio.title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final paywallProvider = Provider.of<PaywallProvider>(context);
        final audio = audioProvider.currentAudio;

        // Gerar novo estilo de visualizador se necessário
        if (audio != null && _currentVisualizerStyle == null) {
          _generateNewVisualizerStyle(audio);
        }

        // Controlar animações baseado no estado de reprodução
        if (audioProvider.isPlaying) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          _rotationController.stop();
          _pulseController.stop();
        }

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
                  _buildAnimatedHeader(screenWidth),
                  
                  // Banner de anúncio para usuários não premium
                  if (!paywallProvider.isPremium)
                    const BannerAdWidget()
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: -0.3, end: 0),
                  
                  // Imagem principal com Hero animation e rotação
                  Expanded(
                    flex: 3,
                    child: _buildAnimatedMusicIcon(screenWidth),
                  ),
                  
                  // Controles de mixagem (se ativados)
                  if (_showMixControls)
                    _buildMixControls(audioProvider),
                  
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

  Widget _buildAnimatedHeader(double screenWidth) {
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
          // Botão para ativar/desativar controles de mixagem
          IconButton(
            icon: Icon(
              _showMixControls ? Icons.layers_clear : Icons.layers,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showMixControls = !_showMixControls;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedMusicIcon(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visualizador circular de fundo
          if (_showVisualizer && _currentVisualizerStyle != null)
            CircularMusicVisualizer(
              size: screenWidth * 0.8,
              isPlaying: Provider.of<AudioProvider>(context, listen: false).isPlaying,
              style: _currentVisualizerStyle!.style,
              primaryColor: _currentVisualizerStyle!.primaryColor,
              secondaryColor: _currentVisualizerStyle!.secondaryColor,
              intensity: VisualizerStyleManager.getIntensityForMusic(
                Provider.of<AudioProvider>(context, listen: false).currentAudio?.category,
                Provider.of<AudioProvider>(context, listen: false).currentAudio?.title,
              ),
            ),
          
          // Ícone central com decoração
          // Container(
          //   width: screenWidth * 0.4,
          //   height: screenWidth * 0.4,
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(screenWidth * 0.05),
          //     boxShadow: [
          //       BoxShadow(
          //         color: (_currentVisualizerStyle?.primaryColor ?? const Color(0xFF6C63FF)).withOpacity(0.3),
          //         blurRadius: screenWidth * 0.1,
          //         offset: Offset(0, screenWidth * 0.05),
          //       ),
          //     ],
          //   ),
          //   child: ClipRRect(
          //     borderRadius: BorderRadius.circular(screenWidth * 0.05),
          //     child: widget.heroTag != null
          //       ? Hero(
          //           tag: widget.heroTag!,
          //           child: Material(
          //             color: Colors.transparent,
          //             child: _buildRotatingIcon(screenWidth),
          //           ),
          //         )
          //       : _buildRotatingIcon(screenWidth),
          //   ),
          // ),
          
          // Botão para alternar visualizador
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_showVisualizer) {
                    _generateNewVisualizerStyle(
                      Provider.of<AudioProvider>(context, listen: false).currentAudio
                    );
                  } else {
                    _showVisualizer = !_showVisualizer;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _showVisualizer ? Icons.refresh : Icons.visibility,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ),
            ),
          ),
          
          // Indicador do estilo atual
          if (_showVisualizer && _currentVisualizerStyle != null)
            Positioned(
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _currentVisualizerStyle!.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().scale(delay: 400.ms, duration: 800.ms, curve: Curves.elasticOut);
  }

  Widget _buildRotatingIcon(double screenWidth) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B73FF),
                  Color(0xFF9644FF),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo interno para simular um disco
                Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                // Ícone principal
                Icon(
                  Icons.self_improvement,
                  size: screenWidth * 0.3,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMixControls(AudioProvider audioProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.layers,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Controles de Mixagem',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (audioProvider.isMixMode)
                TextButton(
                  onPressed: () {
                    audioProvider.disableMixMode();
                  },
                  child: const Text(
                    'Desativar Mix',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Controles de volume se estiver em modo mix
          if (audioProvider.isMixMode) ...[
            Text(
              'Volume da Música: ${(audioProvider.musicVolume * 100).round()}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            Slider(
              value: audioProvider.musicVolume,
              onChanged: (value) {
                audioProvider.setMusicVolume(value);
              },
              activeColor: Colors.blue,
              inactiveColor: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Volume do Som: ${(audioProvider.soundVolume * 100).round()}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            Slider(
              value: audioProvider.soundVolume,
              onChanged: (value) {
                audioProvider.setSoundVolume(value);
              },
              activeColor: Colors.green,
              inactiveColor: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
          ],
          
          // Lista de sons disponíveis
          Text(
            'Sons Ambiente:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableSounds.length,
              itemBuilder: (context, index) {
                final sound = _availableSounds[index];
                final isSelected = audioProvider.currentSound?.id == sound.id;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (audioProvider.currentAudio != null) {
                        if (isSelected) {
                          audioProvider.disableMixMode();
                        } else {
                          audioProvider.enableMixMode(sound);
                          if (audioProvider.isPlaying) {
                            audioProvider.playMix(
                              context,
                              audioProvider.currentAudio!,
                              sound,
                            );
                          }
                        }
                      }
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.blue
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getSoundIcon(sound.title),
                            color: isSelected ? Colors.blue : Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sound.title,
                            style: TextStyle(
                              color: isSelected ? Colors.blue : Colors.white.withOpacity(0.8),
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0);
  }

  IconData _getSoundIcon(String soundTitle) {
    switch (soundTitle.toLowerCase()) {
      case 'chuva':
        return Icons.water_drop;
      case 'oceano':
        return Icons.waves;
      case 'floresta':
        return Icons.forest;
      case 'lareira':
        return Icons.local_fire_department;
      default:
        return Icons.music_note;
    }
  }

  Widget _buildAnimatedControls(
    double screenWidth,
    double screenHeight,
    AudioProvider audioProvider,
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
          
          // Indicador de mix mode
          if (audioProvider.isMixMode && audioProvider.currentSound != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.layers,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mix: ${audioProvider.currentSound!.title}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 750.ms).scale(),
          
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
    AudioProvider audioProvider,
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
                audioProvider.seek(Duration(seconds: value.toInt()));
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
    AudioProvider audioProvider,
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
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: audioProvider.isPlaying ? _pulseAnimation.value : 1.0,
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
                          audioProvider.togglePlayPause(context);
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

