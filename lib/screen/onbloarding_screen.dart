import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildPage("Bem-vindo ao MindWave", "Melhore seu sono, foco e relaxamento."),
      _buildPage("Explore Categorias", "Sons de natureza, meditações, ruídos e mais."),
      _buildPage("Salve e Acompanhe", "Marque favoritos e acompanhe sua jornada."),
    ];

    return Scaffold(
      body: PageView.builder(
        itemCount: pages.length,
        itemBuilder: (context, index) => pages[index],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Começar'),
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => context.go('/categories'),
      ),
    );
  }

  Widget _buildPage(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
