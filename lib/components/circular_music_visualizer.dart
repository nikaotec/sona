import 'dart:math' as math;
import 'package:flutter/material.dart';

enum VisualizerStyle {
  spectrum,
  pulse,
  wave,
  particle,
  ripple,
  galaxy,
  mandala,
  spiral
}

class CircularMusicVisualizer extends StatefulWidget {
  final double size;
  final bool isPlaying;
  final VisualizerStyle style;
  final Color primaryColor;
  final Color secondaryColor;
  final double intensity;

  const CircularMusicVisualizer({
    super.key,
    required this.size,
    required this.isPlaying,
    this.style = VisualizerStyle.spectrum,
    this.primaryColor = const Color(0xFF6B73FF),
    this.secondaryColor = const Color(0xFF9644FF),
    this.intensity = 1.0,
  });

  @override
  State<CircularMusicVisualizer> createState() => _CircularMusicVisualizerState();
}

class _CircularMusicVisualizerState extends State<CircularMusicVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _particleController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _particleAnimation;

  List<double> _spectrumData = [];
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _particleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _generateSpectrumData();
    _generateParticles();
    
    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(CircularMusicVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
    
    if (widget.style != oldWidget.style) {
      _generateSpectrumData();
      _generateParticles();
    }
  }

  void _startAnimations() {
    _mainController.repeat();
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _particleController.repeat();
  }

  void _stopAnimations() {
    _mainController.stop();
    _pulseController.stop();
    _waveController.stop();
    _particleController.stop();
  }

  void _generateSpectrumData() {
    _spectrumData = List.generate(64, (index) {
      return (math.sin(index * 0.1) * 0.5 + 0.5) * widget.intensity;
    });
  }

  void _generateParticles() {
    _particles = List.generate(30, (index) {
      return Particle(
        angle: (index / 30) * 2 * math.pi,
        radius: 50 + math.Random().nextDouble() * 100,
        speed: 0.5 + math.Random().nextDouble() * 1.5,
        size: 2 + math.Random().nextDouble() * 4,
        opacity: 0.3 + math.Random().nextDouble() * 0.7,
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _pulseController,
          _waveController,
          _particleController,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: _getVisualizerPainter(),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }

  CustomPainter _getVisualizerPainter() {
    switch (widget.style) {
      case VisualizerStyle.spectrum:
        return SpectrumVisualizerPainter(
          rotation: _rotationAnimation.value,
          pulse: _pulseAnimation.value,
          spectrumData: _spectrumData,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          isPlaying: widget.isPlaying,
        );
      case VisualizerStyle.pulse:
        return PulseVisualizerPainter(
          rotation: _rotationAnimation.value,
          pulse: _pulseAnimation.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          isPlaying: widget.isPlaying,
        );
      case VisualizerStyle.wave:
        return WaveVisualizerPainter(
          rotation: _rotationAnimation.value,
          wave: _waveAnimation.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          isPlaying: widget.isPlaying,
        );
      case VisualizerStyle.particle:
        return ParticleVisualizerPainter(
          rotation: _rotationAnimation.value,
          particles: _particles,
          particleAnimation: _particleAnimation.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          isPlaying: widget.isPlaying,
        );
      case VisualizerStyle.ripple:
        return RippleVisualizerPainter(
          rotation: _rotationAnimation.value,
          pulse: _pulseAnimation.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          isPlaying: widget.isPlaying,
        );
      case VisualizerStyle.galaxy:
        return GalaxyVisualizerPainter(
          rotation: _rotationAnimation.value,
          particles: _particles,
          particleAnimation: _particleAnimation.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          isPlaying: widget.isPlaying,
        );
      case VisualizerStyle.mandala:
        return MandalaVisualizerPainter(
          rotation: _rotationAnimation.value,
          pulse: _pulseAnimation.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          isPlaying: widget.isPlaying,
        );
      case VisualizerStyle.spiral:
        return SpiralVisualizerPainter(
          rotation: _rotationAnimation.value,
          wave: _waveAnimation.value,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          isPlaying: widget.isPlaying,
        );
    }
  }
}

class Particle {
  double angle;
  double radius;
  double speed;
  double size;
  double opacity;

  Particle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

// Painter para visualizador de espectro
class SpectrumVisualizerPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final List<double> spectrumData;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPlaying;

  SpectrumVisualizerPainter({
    required this.rotation,
    required this.pulse,
    required this.spectrumData,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [primaryColor, secondaryColor],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    // Desenhar barras do espectro
    for (int i = 0; i < spectrumData.length; i++) {
      final angle = (i / spectrumData.length) * 2 * math.pi;
      final barHeight = spectrumData[i] * 50 * pulse;
      
      final startX = math.cos(angle) * radius;
      final startY = math.sin(angle) * radius;
      final endX = math.cos(angle) * (radius + barHeight);
      final endY = math.sin(angle) * (radius + barHeight);
      
      paint.strokeWidth = 3;
      paint.style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }

    // Círculo central
    paint.style = PaintingStyle.fill;
    paint.color = primaryColor.withOpacity(0.3);
    canvas.drawCircle(Offset.zero, radius * 0.3, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para visualizador de pulso
class PulseVisualizerPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPlaying;

  PulseVisualizerPainter({
    required this.rotation,
    required this.pulse,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Múltiplos círculos pulsantes
    for (int i = 0; i < 5; i++) {
      final radius = baseRadius + (i * 20) * pulse;
      final opacity = (1.0 - (i * 0.2)) * 0.8;
      
      paint.color = Color.lerp(primaryColor, secondaryColor, i / 4)!
          .withOpacity(opacity);
      
      canvas.drawCircle(center, radius, paint);
    }

    // Círculo central sólido
    paint.style = PaintingStyle.fill;
    paint.color = primaryColor.withOpacity(0.6);
    canvas.drawCircle(center, baseRadius * 0.5 * pulse, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para visualizador de ondas
class WaveVisualizerPainter extends CustomPainter {
  final double rotation;
  final double wave;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPlaying;

  WaveVisualizerPainter({
    required this.rotation,
    required this.wave,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Desenhar ondas circulares
    for (int ring = 0; ring < 3; ring++) {
      final path = Path();
      bool firstPoint = true;
      
      for (int i = 0; i <= 360; i += 5) {
        final angle = i * math.pi / 180;
        final waveOffset = math.sin(angle * 8 + wave + ring) * 15;
        final currentRadius = radius + (ring * 30) + waveOffset;
        
        final x = math.cos(angle) * currentRadius;
        final y = math.sin(angle) * currentRadius;
        
        if (firstPoint) {
          path.moveTo(x, y);
          firstPoint = false;
        } else {
          path.lineTo(x, y);
        }
      }
      
      path.close();
      
      paint.color = Color.lerp(primaryColor, secondaryColor, ring / 2)!
          .withOpacity(0.8 - ring * 0.2);
      
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para visualizador de partículas
class ParticleVisualizerPainter extends CustomPainter {
  final double rotation;
  final List<Particle> particles;
  final double particleAnimation;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPlaying;

  ParticleVisualizerPainter({
    required this.rotation,
    required this.particles,
    required this.particleAnimation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);

    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final animatedRadius = particle.radius + 
          math.sin(particleAnimation * 2 * math.pi + particle.angle) * 20;
      
      final x = math.cos(particle.angle) * animatedRadius;
      final y = math.sin(particle.angle) * animatedRadius;
      
      paint.color = Color.lerp(primaryColor, secondaryColor, 
          math.sin(particle.angle + particleAnimation * math.pi))!
          .withOpacity(particle.opacity);
      
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para visualizador de ondulações
class RippleVisualizerPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPlaying;

  RippleVisualizerPainter({
    required this.rotation,
    required this.pulse,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Múltiplas ondulações
    for (int i = 0; i < 8; i++) {
      final progress = (pulse + i * 0.125) % 1.0;
      final radius = maxRadius * progress;
      final opacity = (1.0 - progress) * 0.6;
      
      paint.color = Color.lerp(primaryColor, secondaryColor, progress)!
          .withOpacity(opacity);
      
      canvas.drawCircle(center, radius, paint);
    }

    // Centro pulsante
    paint.style = PaintingStyle.fill;
    paint.color = primaryColor.withOpacity(0.8);
    canvas.drawCircle(center, 20 * pulse, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para visualizador de galáxia
class GalaxyVisualizerPainter extends CustomPainter {
  final double rotation;
  final List<Particle> particles;
  final double particleAnimation;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPlaying;

  GalaxyVisualizerPainter({
    required this.rotation,
    required this.particles,
    required this.particleAnimation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final paint = Paint()..style = PaintingStyle.fill;

    // Braços espirais da galáxia
    for (int arm = 0; arm < 3; arm++) {
      final armOffset = (arm * 2 * math.pi / 3) + rotation * 2 * math.pi;
      
      for (int i = 0; i < 50; i++) {
        final t = i / 50.0;
        final angle = armOffset + t * 4 * math.pi;
        final radius = t * size.width * 0.3;
        
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;
        
        final starSize = (1.0 - t) * 3 + 1;
        final opacity = (1.0 - t) * 0.8;
        
        paint.color = Color.lerp(primaryColor, secondaryColor, t)!
            .withOpacity(opacity);
        
        canvas.drawCircle(Offset(x, y), starSize, paint);
      }
    }

    // Centro brilhante
    paint.shader = RadialGradient(
      colors: [primaryColor, secondaryColor.withOpacity(0)],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 30));
    
    canvas.drawCircle(Offset.zero, 30, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para visualizador de mandala
class MandalaVisualizerPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPlaying;

  MandalaVisualizerPainter({
    required this.rotation,
    required this.pulse,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Padrões de mandala
    for (int layer = 0; layer < 5; layer++) {
      final layerRadius = radius * (0.2 + layer * 0.2) * pulse;
      final petals = 6 + layer * 2;
      
      for (int petal = 0; petal < petals; petal++) {
        final angle = (petal / petals) * 2 * math.pi;
        
        final path = Path();
        path.moveTo(0, 0);
        
        for (int i = 0; i <= 20; i++) {
          final t = i / 20.0;
          final petalAngle = angle + math.sin(t * math.pi) * 0.5;
          final petalRadius = layerRadius * math.sin(t * math.pi);
          
          final x = math.cos(petalAngle) * petalRadius;
          final y = math.sin(petalAngle) * petalRadius;
          
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        
        paint.color = Color.lerp(primaryColor, secondaryColor, layer / 4)!
            .withOpacity(0.6);
        
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para visualizador espiral
class SpiralVisualizerPainter extends CustomPainter {
  final double rotation;
  final double wave;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPlaying;

  SpiralVisualizerPainter({
    required this.rotation,
    required this.wave,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Múltiplas espirais
    for (int spiral = 0; spiral < 3; spiral++) {
      final path = Path();
      bool firstPoint = true;
      
      for (int i = 0; i < 200; i++) {
        final t = i / 200.0;
        final angle = t * 6 * math.pi + spiral * 2 * math.pi / 3 + wave;
        final radius = t * maxRadius;
        
        final waveOffset = math.sin(angle * 3 + wave) * 10;
        final currentRadius = radius + waveOffset;
        
        final x = math.cos(angle) * currentRadius;
        final y = math.sin(angle) * currentRadius;
        
        if (firstPoint) {
          path.moveTo(x, y);
          firstPoint = false;
        } else {
          path.lineTo(x, y);
        }
      }
      
      paint.color = Color.lerp(primaryColor, secondaryColor, spiral / 2)!
          .withOpacity(0.8);
      
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

