import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3)); // Tempo de exibição da splash screen
    
    if (mounted) {
      // Verificar se é a primeira vez que o app está sendo executado
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool("onboarding_completed") ?? false;
      
      if (onboardingCompleted) {
        // Se o onboarding já foi completado, vai direto para as categorias
        context.go('/categories');
      } else {
        // Se é a primeira vez, vai para o onboarding
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Cor de fundo escura do tema
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A2A3E), // Gradiente mais claro no topo
              Color(0xFF1A1A2E), // Gradiente mais escuro na base
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone principal do aplicativo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9644FF)], // Gradiente roxo/azul
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.self_improvement, // Ícone que remete a relaxamento/meditação
                  size: 80,
                  color: Colors.white,
                ),
              ).animate().scale(delay: 300.ms, duration: 800.ms, curve: Curves.elasticOut),

              const SizedBox(height: 30),

              // Título do aplicativo
              Text(
                'MindWave',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 10),

              // Subtítulo/Slogan
              Text(
                'Sua jornada para a paz interior.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
