import 'package:flutter/material.dart';
import 'dart:math' as math;

class AudioSpectrumVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final int barCount;
  final double animationSpeed;

  const AudioSpectrumVisualizer({
    super.key,
    required this.isPlaying,
    this.size = 200,
    this.primaryColor = const Color(0xFF6B73FF),
    this.secondaryColor = const Color(0xFF9644FF),
    this.barCount = 32,
    this.animationSpeed = 1.0,
  });

  @override
  State<AudioSpectrumVisualizer> createState() => _AudioSpectrumVisualizerState();
}

class _AudioSpectrumVisualizerState extends State<AudioSpectrumVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;
  
  final List<double> _barHeights = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: (100 / widget.animationSpeed).round()),
      vsync: this,
    );

    _initializeBars();
    
    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _initializeBars() {
    _barControllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(
          milliseconds: 150 + _random.nextInt(200),
        ),
        vsync: this,
      ),
    );

    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _barHeights.addAll(
      List.generate(widget.barCount, (index) => 0.1 + _random.nextDouble() * 0.9),
    );
  }

  void _startAnimation() {
    _animationController.repeat();
    _animationController.addListener(_updateBars);
  }

  void _stopAnimation() {
    _animationController.stop();
    _animationController.removeListener(_updateBars);
    
    // Animar todas as barras para baixo
    for (int i = 0; i < _barControllers.length; i++) {
      _barControllers[i].animateTo(0.1);
    }
  }

  void _updateBars() {
    if (!mounted) return;
    
    // Simular dados de áudio reais com diferentes frequências
    for (int i = 0; i < widget.barCount; i++) {
      final frequency = (i + 1) / widget.barCount;
      final baseHeight = 0.1 + (math.sin(_animationController.value * 2 * math.pi * frequency) + 1) / 2 * 0.9;
      final randomVariation = _random.nextDouble() * 0.3;
      final targetHeight = (baseHeight + randomVariation).clamp(0.1, 1.0);
      
      _barControllers[i].animateTo(targetHeight);
    }
  }

  @override
  void didUpdateWidget(AudioSpectrumVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: SpectrumPainter(
          barAnimations: _barAnimations,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          barCount: widget.barCount,
        ),
      ),
    );
  }
}

class SpectrumPainter extends CustomPainter {
  final List<Animation<double>> barAnimations;
  final Color primaryColor;
  final Color secondaryColor;
  final int barCount;

  SpectrumPainter({
    required this.barAnimations,
    required this.primaryColor,
    required this.secondaryColor,
    required this.barCount,
  }) : super(repaint: Listenable.merge(barAnimations));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / barCount;
    final maxHeight = size.height * 0.8;

    for (int i = 0; i < barCount; i++) {
      final barHeight = barAnimations[i].value * maxHeight;
      final x = i * barWidth + barWidth * 0.2;
      final y = size.height - barHeight;
      
      // Gradiente baseado na altura da barra
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          primaryColor,
          secondaryColor,
          Colors.white.withOpacity(0.8),
        ],
        stops: const [0.0, 0.7, 1.0],
      );

      final rect = Rect.fromLTWH(x, y, barWidth * 0.6, barHeight);
      paint.shader = gradient.createShader(rect);
      
      // Desenhar barra com bordas arredondadas
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(barWidth * 0.1),
      );
      
      canvas.drawRRect(rrect, paint);
      
      // Adicionar reflexo
      if (barHeight > maxHeight * 0.3) {
        final reflectionPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        
        final reflectionRect = Rect.fromLTWH(
          x + barWidth * 0.1,
          y,
          barWidth * 0.2,
          barHeight * 0.6,
        );
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            reflectionRect,
            Radius.circular(barWidth * 0.05),
          ),
          reflectionPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

