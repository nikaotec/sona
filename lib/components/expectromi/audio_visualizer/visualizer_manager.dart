import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sona/components/expectromi/audio_visualizer/audio_espectron_manager.dart';
import 'package:sona/components/expectromi/audio_visualizer/circular_wave_visualizer.dart';
import 'package:sona/components/expectromi/audio_visualizer/particle_visualzier.dart';

enum VisualizerType {
  spectrum,
  circularWave,
  particle,
}

class VisualizerManager extends StatefulWidget {
  final bool isPlaying;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final bool allowTypeChange;
  final VisualizerType? initialType;
  final bool isCompact; // Novo parâmetro

  const VisualizerManager({
    super.key,
    required this.isPlaying,
    this.size = 200,
    this.primaryColor = const Color(0xFF6B73FF),
    this.secondaryColor = const Color(0xFF9644FF),
    this.allowTypeChange = true,
    this.initialType,
    this.isCompact = false, // Valor padrão
  });

  @override
  State<VisualizerManager> createState() => _VisualizerManagerState();
}

class _VisualizerManagerState extends State<VisualizerManager>
    with TickerProviderStateMixin {
  late VisualizerType _currentType;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _currentType = widget.initialType ?? VisualizerType.spectrum;
    
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));
    
    _transitionController.forward();
  }

  void _changeVisualizerType() {
    if (!widget.allowTypeChange) return;
    
    HapticFeedback.lightImpact();
    
    _transitionController.reverse().then((_) {
      setState(() {
        switch (_currentType) {
          case VisualizerType.spectrum:
            _currentType = VisualizerType.circularWave;
            break;
          case VisualizerType.circularWave:
            _currentType = VisualizerType.particle;
            break;
          case VisualizerType.particle:
            _currentType = VisualizerType.spectrum;
            break;
        }
      });
      _transitionController.forward();
    });
  }

  Widget _buildCurrentVisualizer() {
    // Se for compacto, sempre usa o visualizador de espectro com menos barras
    if (widget.isCompact) {
      return AudioSpectrumVisualizer(
        isPlaying: widget.isPlaying,
        size: widget.size,
        primaryColor: widget.primaryColor,
        secondaryColor: widget.secondaryColor,
        barCount: 8, // Menos barras para visualização compacta
      );
    }

    switch (_currentType) {
      case VisualizerType.spectrum:
        return AudioSpectrumVisualizer(
          isPlaying: widget.isPlaying,
          size: widget.size,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        );
      case VisualizerType.circularWave:
        return CircularWaveVisualizer(
          isPlaying: widget.isPlaying,
          size: widget.size,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        );
      case VisualizerType.particle:
        return ParticleVisualizer(
          isPlaying: widget.isPlaying,
          size: widget.size,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        );
    }
  }

  String _getVisualizerName() {
    switch (_currentType) {
      case VisualizerType.spectrum:
        return 'Espectro';
      case VisualizerType.circularWave:
        return 'Ondas';
      case VisualizerType.particle:
        return 'Partículas';
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Visualizador principal
        GestureDetector(
          onTap: widget.allowTypeChange ? _changeVisualizerType : null,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size * 0.05),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.3),
                  blurRadius: widget.size * 0.1,
                  offset: Offset(0, widget.size * 0.05),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size * 0.05),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2A2A3E),
                      Color(0xFF1A1A2E),
                    ],
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: _buildCurrentVisualizer(),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        
        // Indicador do tipo de visualizador (apenas se não for compacto)
        if (widget.allowTypeChange && !widget.isCompact) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.primaryColor.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: widget.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _getVisualizerName(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

