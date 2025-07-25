import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularWaveVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final int waveCount;
  final double animationSpeed;

  const CircularWaveVisualizer({
    super.key,
    required this.isPlaying,
    this.size = 200,
    this.primaryColor = const Color(0xFF6B73FF),
    this.secondaryColor = const Color(0xFF9644FF),
    this.waveCount = 3,
    this.animationSpeed = 1.0,
  });

  @override
  State<CircularWaveVisualizer> createState() => _CircularWaveVisualizerState();
}

class _CircularWaveVisualizerState extends State<CircularWaveVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _waveControllers;
  late List<Animation<double>> _waveAnimations;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: Duration(seconds: (20 / widget.animationSpeed).round()),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _initializeWaves();
    
    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _initializeWaves() {
    _waveControllers = List.generate(
      widget.waveCount,
      (index) => AnimationController(
        duration: Duration(
          milliseconds: (1000 + index * 200) ~/ widget.animationSpeed,
        ),
        vsync: this,
      ),
    );

    _waveAnimations = _waveControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  void _startAnimation() {
    _rotationController.repeat();
    
    for (int i = 0; i < _waveControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted && widget.isPlaying) {
          _waveControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimation() {
    _rotationController.stop();
    for (final controller in _waveControllers) {
      controller.stop();
    }
  }

  @override
  void didUpdateWidget(CircularWaveVisualizer oldWidget) {
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
    _rotationController.dispose();
    for (final controller in _waveControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationAnimation, ..._waveAnimations]),
        builder: (context, child) {
          return CustomPaint(
            painter: CircularWavePainter(
              waveAnimations: _waveAnimations,
              rotationValue: _rotationAnimation.value,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              waveCount: widget.waveCount,
            ),
          );
        },
      ),
    );
  }
}

class CircularWavePainter extends CustomPainter {
  final List<Animation<double>> waveAnimations;
  final double rotationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final int waveCount;

  CircularWavePainter({
    required this.waveAnimations,
    required this.rotationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.waveCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.15;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationValue);
    canvas.translate(-center.dx, -center.dy);

    // Desenhar ondas concêntricas
    for (int i = 0; i < waveCount; i++) {
      final waveValue = waveAnimations[i].value;
      final radius = baseRadius + (i * size.width * 0.08) + (waveValue * size.width * 0.05);
      
      // Gradiente para cada onda
      final gradient = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.8 - (i * 0.2)),
          secondaryColor.withOpacity(0.6 - (i * 0.15)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (waveValue * 3.0);

      // Desenhar círculo principal
      canvas.drawCircle(center, radius, paint);
      
      // Adicionar pontos de energia
      _drawEnergyPoints(canvas, center, radius, waveValue, i);
    }

    // Desenhar centro pulsante
    _drawPulsatingCenter(canvas, center, baseRadius * 0.6);
    
    canvas.restore();
  }

  void _drawEnergyPoints(Canvas canvas, Offset center, double radius, double waveValue, int waveIndex) {
    final pointCount = 8 + (waveIndex * 4);
    final pointPaint = Paint()
      ..color = primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < pointCount; i++) {
      final angle = (i / pointCount) * 2 * math.pi;
      final pointRadius = 2.0 + (waveValue * 4.0);
      final distance = radius + (math.sin(waveValue * 2 * math.pi) * 5);
      
      final pointX = center.dx + math.cos(angle) * distance;
      final pointY = center.dy + math.sin(angle) * distance;
      
      canvas.drawCircle(
        Offset(pointX, pointY),
        pointRadius,
        pointPaint,
      );
    }
  }

  void _drawPulsatingCenter(Canvas canvas, Offset center, double baseRadius) {
    final centerGradient = RadialGradient(
      colors: [
        primaryColor,
        secondaryColor,
        primaryColor.withOpacity(0.3),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final centerPaint = Paint()
      ..shader = centerGradient.createShader(
        Rect.fromCircle(center: center, radius: baseRadius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, baseRadius, centerPaint);
    
    // Adicionar brilho central
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, baseRadius * 0.3, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

