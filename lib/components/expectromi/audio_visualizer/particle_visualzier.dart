import 'package:flutter/material.dart';
import 'dart:math' as math;

class Particle {
  Offset position;
  Offset velocity;
  double life;
  double maxLife;
  double size;
  Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
  });

  void update() {
    position += velocity;
    life -= 0.016; // Aproximadamente 60 FPS
    
    // Aplicar gravidade sutil
    velocity = Offset(velocity.dx * 0.99, velocity.dy + 0.1);
  }

  bool get isDead => life <= 0;
  
  double get opacity => (life / maxLife).clamp(0.0, 1.0);
}

class ParticleVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final int maxParticles;
  final double animationSpeed;

  const ParticleVisualizer({
    super.key,
    required this.isPlaying,
    this.size = 200,
    this.primaryColor = const Color(0xFF6B73FF),
    this.secondaryColor = const Color(0xFF9644FF),
    this.maxParticles = 50,
    this.animationSpeed = 1.0,
  });

  @override
  State<ParticleVisualizer> createState() => _ParticleVisualizerState();
}

class _ParticleVisualizerState extends State<ParticleVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  late Offset _center;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16), // ~60 FPS
      vsync: this,
    );

    _center = Offset(widget.size / 2, widget.size / 2);
    
    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _animationController.repeat();
    _animationController.addListener(_updateParticles);
  }

  void _stopAnimation() {
    _animationController.stop();
    _animationController.removeListener(_updateParticles);
  }

  void _updateParticles() {
    if (!mounted) return;

    // Remover partículas mortas
    _particles.removeWhere((particle) => particle.isDead);

    // Atualizar partículas existentes
    for (final particle in _particles) {
      particle.update();
    }

    // Adicionar novas partículas se estiver tocando
    if (widget.isPlaying && _particles.length < widget.maxParticles) {
      _addNewParticles();
    }

    setState(() {});
  }

  void _addNewParticles() {
    final particlesToAdd = math.min(3, widget.maxParticles - _particles.length);
    
    for (int i = 0; i < particlesToAdd; i++) {
      _particles.add(_createParticle());
    }
  }

  Particle _createParticle() {
    // Posição inicial aleatória ao redor do centro
    final angle = _random.nextDouble() * 2 * math.pi;
    final distance = _random.nextDouble() * widget.size * 0.1;
    final startPosition = Offset(
      _center.dx + math.cos(angle) * distance,
      _center.dy + math.sin(angle) * distance,
    );

    // Velocidade baseada na "intensidade" da música
    final speed = 1.0 + _random.nextDouble() * 3.0;
    final velocityAngle = angle + (_random.nextDouble() - 0.5) * 0.5;
    final velocity = Offset(
      math.cos(velocityAngle) * speed,
      math.sin(velocityAngle) * speed,
    );

    // Propriedades visuais
    final life = 2.0 + _random.nextDouble() * 3.0;
    final size = 2.0 + _random.nextDouble() * 4.0;
    
    // Cor baseada na posição
    final colorLerp = _random.nextDouble();
    final color = Color.lerp(widget.primaryColor, widget.secondaryColor, colorLerp)!;

    return Particle(
      position: startPosition,
      velocity: velocity,
      life: life,
      maxLife: life,
      size: size,
      color: color,
    );
  }

  @override
  void didUpdateWidget(ParticleVisualizer oldWidget) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: ParticlePainter(
          particles: _particles,
          center: _center,
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Offset center;

  ParticlePainter({
    required this.particles,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Desenhar conexões entre partículas próximas
    _drawConnections(canvas);
    
    // Desenhar partículas
    for (final particle in particles) {
      _drawParticle(canvas, particle);
    }
    
    // Desenhar centro energético
    _drawEnergyCenter(canvas, size);
  }

  void _drawConnections(Canvas canvas) {
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final particle1 = particles[i];
        final particle2 = particles[j];
        
        final distance = (particle1.position - particle2.position).distance;
        
        if (distance < 50) {
          final opacity = (1.0 - distance / 50) * 0.3;
          connectionPaint.color = particle1.color.withOpacity(
            opacity * particle1.opacity * particle2.opacity,
          );
          
          canvas.drawLine(particle1.position, particle2.position, connectionPaint);
        }
      }
    }
  }

  void _drawParticle(Canvas canvas, Particle particle) {
    final paint = Paint()
      ..color = particle.color.withOpacity(particle.opacity)
      ..style = PaintingStyle.fill;

    // Desenhar partícula principal
    canvas.drawCircle(particle.position, particle.size, paint);
    
    // Adicionar brilho
    if (particle.opacity > 0.5) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * 0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(particle.position, particle.size * 0.5, glowPaint);
    }
  }

  void _drawEnergyCenter(Canvas canvas, Size size) {
    final centerGradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.8),
        const Color(0xFF6B73FF).withOpacity(0.6),
        const Color(0xFF9644FF).withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final centerPaint = Paint()
      ..shader = centerGradient.createShader(
        Rect.fromCircle(center: center, radius: 30),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 30, centerPaint);
    
    // Núcleo central
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 8, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

