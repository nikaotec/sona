import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/onboarding_provider.dart';
import '../model/onboarding_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Inicia as animações
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _animateToNextPage() {
    _fadeController.reset();
    _slideController.reset();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    ).then((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  void _animateToPreviousPage() {
    _fadeController.reset();
    _slideController.reset();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    ).then((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWelcomeScreen(provider),
                _buildObjectiveScreen(provider),
                _buildMoodScreen(provider),
                _buildStyleScreen(provider),
                _buildTimeScreen(provider),
                _buildAIResultScreen(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeScreen(OnboardingProvider provider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone com animação de escala
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6C63FF).withOpacity(0.3),
                            const Color(0xFF6C63FF).withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.waves,
                        size: 80,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              // Título com animação de fade
              const Text(
                'Olá, que bom ter você aqui.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
              const SizedBox(height: 20),
              // Subtítulo com animação de fade
              const Text(
                'Vamos descobrir como o MindWave pode te ajudar a dormir melhor, focar e relaxar.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
              const SizedBox(height: 60),
              // Botão com animação de escala e hover
              AnimatedButton(
                onPressed: () {
                  provider.nextStep();
                  _animateToNextPage();
                },
                child: const Text(
                  'Começar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveScreen(OnboardingProvider provider) {
    final objectives = [
      OnboardingOption(
        id: 'dormir_melhor',
        title: 'Dormir melhor',
        description: 'Melhorar a qualidade do sono',
      ),
      OnboardingOption(
        id: 'reduzir_ansiedade',
        title: 'Reduzir ansiedade',
        description: 'Diminuir os níveis de ansiedade',
      ),
      OnboardingOption(
        id: 'focar_estudos',
        title: 'Focar nos estudos/trabalho',
        description: 'Aumentar concentração e produtividade',
      ),
      OnboardingOption(
        id: 'relaxar',
        title: 'Relaxar após um dia agitado',
        description: 'Encontrar momentos de paz',
      ),
      OnboardingOption(
        id: 'meditar',
        title: 'Meditar com regularidade',
        description: 'Desenvolver uma prática de meditação',
      ),
    ];

    return _buildAnimatedSelectionScreen(
      title: 'Qual seu principal objetivo com o MindWave?',
      options: objectives,
      onSelect: (option) {
        provider.setObjetivo(option.id);
        provider.nextStep();
        _animateToNextPage();
      },
    );
  }

  Widget _buildMoodScreen(OnboardingProvider provider) {
    final moods = [
      OnboardingOption(
        id: 'calmo',
        title: 'Calmo(a)',
        description: 'Me sinto tranquilo e em paz',
      ),
      OnboardingOption(
        id: 'estressado',
        title: 'Estressado(a)',
        description: 'Sinto tensão e pressão',
      ),
      OnboardingOption(
        id: 'ansioso',
        title: 'Ansioso(a)',
        description: 'Sinto preocupação e inquietação',
      ),
      OnboardingOption(
        id: 'cansado',
        title: 'Cansado(a)',
        description: 'Me sinto exausto e sem energia',
      ),
      OnboardingOption(
        id: 'distraido',
        title: 'Distraído(a)',
        description: 'Tenho dificuldade para me concentrar',
      ),
    ];

    return _buildAnimatedSelectionScreen(
      title: 'Escolha o que melhor descreve como você se sente neste momento.',
      options: moods,
      onSelect: (option) {
        provider.setHumor(option.id);
        provider.nextStep();
        _animateToNextPage();
      },
      showBackButton: true,
      onBack: () {
        provider.previousStep();
        _animateToPreviousPage();
      },
    );
  }

  Widget _buildStyleScreen(OnboardingProvider provider) {
    final styles = [
      OnboardingOption(
        id: 'natureza',
        title: 'Sons da natureza',
        description: 'Chuva, mar, vento',
      ),
      OnboardingOption(
        id: 'binaural',
        title: 'Batidas suaves',
        description: 'Binaural, ASMR',
      ),
      OnboardingOption(
        id: 'instrumental',
        title: 'Música instrumental relaxante',
        description: 'Melodias suaves e harmoniosas',
      ),
      OnboardingOption(
        id: 'voz_guiada',
        title: 'Voz suave guiando a meditação',
        description: 'Meditações guiadas',
      ),
      OnboardingOption(
        id: 'nao_sei',
        title: 'Não tenho certeza ainda',
        description: 'Quero explorar as opções',
      ),
    ];

    return _buildAnimatedSelectionScreen(
      title: 'Qual tipo de som te acalma mais?',
      options: styles,
      onSelect: (option) {
        provider.setEstilo(option.id);
        provider.nextStep();
        _animateToNextPage();
      },
      showBackButton: true,
      onBack: () {
        provider.previousStep();
        _animateToPreviousPage();
      },
    );
  }

  Widget _buildTimeScreen(OnboardingProvider provider) {
    final times = [
      OnboardingOption(
        id: 'deitar_dormir',
        title: 'Ao deitar para dormir',
        description: 'No final do dia, na cama',
      ),
      OnboardingOption(
        id: 'durante_dia',
        title: 'Durante o dia',
        description: 'Pausa mental no trabalho/estudos',
      ),
      OnboardingOption(
        id: 'antes_estudar',
        title: 'Antes de estudar ou trabalhar',
        description: 'Para me preparar e focar',
      ),
      OnboardingOption(
        id: 'ao_acordar',
        title: 'Quando acordo',
        description: 'Para começar o dia bem',
      ),
      OnboardingOption(
        id: 'tarde_por_sol',
        title: 'À tarde ou no pôr do sol',
        description: 'Momento de transição do dia',
      ),
    ];

    return _buildAnimatedSelectionScreen(
      title: 'Quando você mais sente necessidade de relaxar?',
      options: times,
      onSelect: (option) {
        provider.setHorario(option.id);
        provider.nextStep();
        _animateToNextPage();
        provider.generateRecommendation();
      },
      showBackButton: true,
      onBack: () {
        provider.previousStep();
        _animateToPreviousPage();
      },
    );
  }

  Widget _buildAIResultScreen(OnboardingProvider provider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (provider.isLoading) ...[
                // Animação de loading personalizada
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 3,
                            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.lerp(
                                const Color(0xFF6C63FF),
                                const Color(0xFF9644FF),
                                value,
                              )!,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.psychology,
                          size: 40,
                          color: Colors.white.withOpacity(value),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                const Text(
                  'Gerando sua jornada personalizada...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2000.ms, color: Colors.white24),
                const SizedBox(height: 20),
                const Text(
                  'Estamos analisando suas preferências para criar a experiência perfeita para você.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms),
              ] else if (provider.errorMessage != null) ...[
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ).animate().shake(),
                const SizedBox(height: 40),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(),
                const SizedBox(height: 40),
                AnimatedButton(
                  onPressed: () {
                    provider.generateRecommendation();
                  },
                  child: const Text(
                    'Tentar Novamente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ] else if (provider.onboardingData?.recomendacaoIA != null) ...[
                const Icon(
                  Icons.psychology,
                  size: 80,
                  color: Color(0xFF6C63FF),
                ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 40),
                const Text(
                  'Sua jornada personalizada está pronta!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    provider.onboardingData!.recomendacaoIA!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 40),
                AnimatedButton(
                  onPressed: () {
                    context.go('/categories');
                  },
                  child: const Text(
                    'Começar Jornada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSelectionScreen({
    required String title,
    required List<OnboardingOption> options,
    required Function(OnboardingOption) onSelect,
    bool showBackButton = false,
    VoidCallback? onBack,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              if (showBackButton)
                Align(
                  alignment: Alignment.topLeft,
                  child: AnimatedButton(
                    onPressed: onBack,
                    isIconButton: true,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 40),
                    Expanded(
                      child: ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: AnimatedOptionCard(
                              option: option,
                              index: index,
                              onTap: () => onSelect(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget personalizado para botões animados
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isIconButton;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isIconButton = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
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
      end: 0.95,
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
    if (widget.isIconButton) {
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
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                  ),
                ),
                child: widget.child,
              ),
            );
          },
        ),
      );
    }

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
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9644FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}

// Widget para cards de opção animados
class AnimatedOptionCard extends StatefulWidget {
  final OnboardingOption option;
  final int index;
  final VoidCallback onTap;

  const AnimatedOptionCard({
    super.key,
    required this.option,
    required this.index,
    required this.onTap,
  });

  @override
  State<AnimatedOptionCard> createState() => _AnimatedOptionCardState();
}

class _AnimatedOptionCardState extends State<AnimatedOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _colorAnimation = ColorTween(
      begin: const Color(0xFF2A2A3E),
      end: const Color(0xFF6C63FF).withOpacity(0.1),
    ).animate(_controller);
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
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.option.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.option.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate(delay: (widget.index * 100).ms).fadeIn().slideX(begin: 0.3, end: 0);
  }
}
