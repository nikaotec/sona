import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sona/provider/user_data_provider.dart';
import 'package:sona/service/openai_service.dart';
import '../provider/onboarding_provider.dart';
import '../model/onboarding_model.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isEditMode; // Para distinguir entre onboarding inicial e edição
  const OnboardingScreen({
    super.key,
    this.isEditMode = false,
    });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
 late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentPage = 0;
  bool _isLoading = false;
  String _aiResponse = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    
    // Se estiver em modo de edição, carregar dados existentes
    if (widget.isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingData();
      });
    }
  }

  void _loadExistingData() {
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    
    if (userDataProvider.onboardingData != null) {
      final data = userDataProvider.onboardingData!;
      onboardingProvider.setObjetivo(data.objetivo ?? '');
      onboardingProvider.setHumor(data.humor ?? '');
      onboardingProvider.setEstilo(data.estilo ?? '');
      onboardingProvider.setHorario(data.horario ?? '');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      setState(() {
        _currentPage++;
      });
      _slideController.reset();
      _slideController.forward();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _slideController.reset();
      _slideController.forward();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _generateAIResponse() async {
    setState(() {
      _isLoading = true;
    });

    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final openAIService = OpenAIService();

    try {
      final response = await openAIService.generatePersonalizedRecommendation(
        objetivo: onboardingProvider.objetivo,
        humor: onboardingProvider.humor,
        estilo: onboardingProvider.estilo,
        horario: onboardingProvider.horario,
      );

      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });

      // Salvar dados no perfil do usuário
      await _saveUserData();
    } catch (e) {
      setState(() {
        _aiResponse = _getFallbackMessage();
        _isLoading = false;
      });
      await _saveUserData();
    }
  }

  

  Future<void> _saveUserData() async {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);

    final onboardingData = OnboardingData(
      objetivo: onboardingProvider.objetivo,
      humor: onboardingProvider.humor,
      estilo: onboardingProvider.estilo,
      horario: onboardingProvider.horario,
      aiResponse: _aiResponse,
      completedAt: DateTime.now(),
    );

    await userDataProvider.saveOnboardingData(onboardingData);
  }

  String _getFallbackMessage() {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    
    if (onboardingProvider.objetivo.contains('Dormir melhor')) {
      return 'Baseado em suas preferências, recomendamos sons relaxantes da natureza para uma noite tranquila. Experimente nossa categoria "Natureza" com sons de chuva e oceano.';
    } else if (onboardingProvider.objetivo.contains('Reduzir ansiedade')) {
      return 'Para reduzir a ansiedade, criamos uma seleção de meditações guiadas e sons binaurais. Explore nossa categoria "Meditação" para encontrar paz interior.';
    } else if (onboardingProvider.objetivo.contains('Focar')) {
      return 'Para melhorar o foco, recomendamos sons binaurais e música instrumental. Nossa categoria "Binaural" foi especialmente selecionada para você.';
    }
    
    return 'Criamos uma experiência personalizada baseada em suas preferências. Explore nossas categorias para descobrir o que mais combina com você.';
  }


  void _finishOnboarding() async {
    if (!widget.isEditMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    }

    if (widget.isEditMode) {
      // Se estiver editando, voltar para o perfil
      context.go('/profile');
    } else {
      // Se for onboarding inicial, ir para categorias
      context.go('/categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A2A3E),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header com indicador de progresso e botão voltar
              _buildHeader(),
              
              // Conteúdo das páginas
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomePage(),
                    _buildObjectivePage(),
                    _buildMoodPage(),
                    _buildStylePage(),
                    _buildTimePage(),
                    _buildResultPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Botão voltar (apenas se não for a primeira página)
          if (_currentPage > 0)
            AnimatedButton(
              onPressed: _previousPage,
              isIconButton: true,
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ).animate().fadeIn().slideX(begin: -0.3, end: 0)
          else if (widget.isEditMode)
            const SizedBox(width: 48), // Espaço para alinhar com o botão de fechar
          
          const Spacer(),
          
          // Indicador de progresso
          Row(
            children: List.generate(6, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index <= _currentPage 
                      ? const Color(0xFF6C63FF) 
                      : Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ).animate().scale(delay: (index * 100).ms);
            }),
          ),
          
          const Spacer(),
          
          // Botão de fechar (apenas em modo de edição)
          if (widget.isEditMode)
            AnimatedButton(
              onPressed: () => context.go("/profile"),
              isIconButton: true,
              child: const Icon(Icons.close, color: Colors.white),
            ).animate().fadeIn().slideX(begin: 0.3, end: 0)
          else if (_currentPage == 0)
            const SizedBox(width: 48), // Espaço para alinhar quando não há botão voltar nem fechar
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // Ícone principal
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9644FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.self_improvement,
                size: 60,
                color: Colors.white,
              ),
            ).animate().scale(delay: 300.ms, duration: 800.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 40),
            
            // Título
            Text(
              widget.isEditMode 
                  ? 'Editar Preferências'
                  : 'Olá, que bom ter você aqui!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 20),
            
            // Subtítulo
            Text(
              widget.isEditMode
                  ? 'Atualize suas preferências para uma experiência ainda mais personalizada.'
                  : 'Vamos descobrir como o MindWave pode te ajudar a dormir melhor, focar e relaxar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 60),
            
            // Botão começar
            AnimatedButton(
              onPressed: _nextPage,
              child: Text(
                widget.isEditMode ? 'Editar' : 'Começar',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.5, end: 0),
          ],
        ),
      ),
    ));
  }

  Widget _buildObjectivePage() {
    return SlideTransition(
      position: _slideAnimation,
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Título
                const Text(
                  'Qual seu principal objetivo com o MindWave?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideY(begin: -0.3, end: 0),
                
                const SizedBox(height: 40),
                
                // Opções
                ...['Dormir melhor', 'Reduzir ansiedade', 'Focar nos estudos/trabalho', 'Relaxar após um dia agitado', 'Meditar com regularidade']
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return AnimatedOptionCard(
                    text: option,
                    isSelected: provider.objetivo == option,
                    onTap: () => provider.setObjetivo(option),
                    delay: (index * 100).ms,
                  );
                }),
                
                const SizedBox(height: 40),
                
                // Botão continuar
                if (provider.objetivo.isNotEmpty)
                  AnimatedButton(
                    onPressed: _nextPage,
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
              ],
            ),
          ));
        },
      ),
    );
  }

  Widget _buildMoodPage() {
    return SlideTransition(
      position: _slideAnimation,
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Text(
                  'Como você está se sentindo agora?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideY(begin: -0.3, end: 0),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Escolha o que melhor descreve como você se sente neste momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3, end: 0),
                
                const SizedBox(height: 40),
                
                ...['Calmo(a)', 'Estressado(a)', 'Ansioso(a)', 'Cansado(a)', 'Distraído(a)']
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return AnimatedOptionCard(
                    text: option,
                    isSelected: provider.humor == option,
                    onTap: () => provider.setHumor(option),
                    delay: (index * 100).ms,
                  );
                }),
                
                const SizedBox(height: 40),
                
                if (provider.humor.isNotEmpty)
                  AnimatedButton(
                    onPressed: _nextPage,
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
              ],
            ),
          ));
        },
      ),
    );
  }

  Widget _buildStylePage() {
    return SlideTransition(
      position: _slideAnimation,
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Text(
                  'Qual tipo de som te acalma mais?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideY(begin: -0.3, end: 0),
                
                const SizedBox(height: 40),
                
                ...['Sons da natureza (chuva, mar, vento)', 'Batidas suaves (binaural, ASMR)', 'Música instrumental relaxante', 'Voz suave guiando a meditação', 'Não tenho certeza ainda']
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return AnimatedOptionCard(
                    text: option,
                    isSelected: provider.estilo == option,
                    onTap: () => provider.setEstilo(option),
                    delay: (index * 100).ms,
                  );
                }),
                
                const SizedBox(height: 40),
                
                if (provider.estilo.isNotEmpty)
                  AnimatedButton(
                    onPressed: _nextPage,
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
              ],
            ),
          ));
        },
      ),
    );
  }

  Widget _buildTimePage() {
    return SlideTransition(
      position: _slideAnimation,
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Text(
                  'Qual o melhor horário para você relaxar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideY(begin: -0.3, end: 0),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Quando você mais sente necessidade de relaxar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3, end: 0),
                
                const SizedBox(height: 40),
                
                ...['Ao deitar para dormir', 'Durante o dia (pausa mental)', 'Antes de estudar ou trabalhar', 'Quando acordo', 'À tarde ou no pôr do sol']
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return AnimatedOptionCard(
                    text: option,
                    isSelected: provider.horario == option,
                    onTap: () => provider.setHorario(option),
                    delay: (index * 100).ms,
                  );
                }),
                
                const SizedBox(height: 40),
                
                if (provider.horario.isNotEmpty)
                  AnimatedButton(
                    onPressed: () {
                      _nextPage();
                      _generateAIResponse();
                    },
                    child: const Text(
                      'Finalizar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
              ],
            ),
          ));
        },
      ),
    );
  }

  Widget _buildResultPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          if (_isLoading) ...[
            // Loading animation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9644FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ).animate().scale().then().shimmer(duration: 2000.ms),
            
            const SizedBox(height: 30),
            
            const Text(
              'Gerando sua jornada personalizada...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn().then().shimmer(duration: 2000.ms),
            
            const SizedBox(height: 15),
            
            const Text(
              'Estamos criando uma experiência única para você',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ).animate().fadeIn(delay: 500.ms),
          ] else ...[
            // Result
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Color(0xFF6C63FF),
            ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 30),
            
            const Text(
              'Sua jornada está pronta!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                ),
              ),
              child: Text(
                _aiResponse,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 40),
            
            AnimatedButton(
              onPressed: () async {
                 _finishOnboarding();
                if (widget.isEditMode) {
                  context.go("/profile");
                }
              },
              child: Text(
                widget.isEditMode ? 'Salvar Alterações' : 'Começar Jornada',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.5, end: 0),
          ],
        ],
      ),
    ));
  }
}

// Widgets reutilizáveis (AnimatedButton e AnimatedOptionCard)
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

class AnimatedOptionCard extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration delay;

  const AnimatedOptionCard({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.delay,
  });

  @override
  State<AnimatedOptionCard> createState() => _AnimatedOptionCardState();
}

class _AnimatedOptionCardState extends State<AnimatedOptionCard>
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
      end: 0.98,
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
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isSelected 
                    ? const Color(0xFF6C63FF).withOpacity(0.2)
                    : const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected 
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.1),
                  width: 2,
                ),
                boxShadow: widget.isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (widget.isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF6C63FF),
                      size: 24,
                    ).animate().scale(curve: Curves.elasticOut),
                ],
              ),
            ),
          );
        },
      ),
    ).animate(delay: widget.delay).fadeIn().slideX(begin: 0.3, end: 0);
  }
}

