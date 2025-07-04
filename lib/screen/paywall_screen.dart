import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/paywall_provider.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final paywall = Provider.of<PaywallProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Assinatura Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Desbloqueie seu Potencial de Relaxamento',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Assine o plano Premium para ter acesso ilimitado a todos os recursos e uma experiência sem interrupções.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildPremiumBenefit(
                Icons.ad_units, 'Sem Anúncios', 'Desfrute de um ambiente totalmente livre de anúncios.'),
            _buildPremiumBenefit(
                Icons.music_note, 'Sons Ilimitados e Exclusivos', 'Acesse nossa biblioteca completa de áudios e meditações.'),
            _buildPremiumBenefit(
                Icons.self_improvement, 'Programas de Meditação Guiada', 'Siga programas completos para aprimorar sua prática.'),
            _buildPremiumBenefit(
                Icons.download, 'Downloads para Ouvir Offline', 'Baixe seus áudios favoritos e ouça a qualquer hora, em qualquer lugar.'),
            _buildPremiumBenefit(
                Icons.timer, 'Ferramentas Avançadas', 'Timer de sono, trilhas combinadas e muito mais.'),
            const SizedBox(height: 30),
            if (!paywall.isPremium && paywall.dailyPlayCount >= 3) // Show this only if user hit limit and not premium
              const Text(
                'Você atingiu o limite diário de 3 áudios gratuitos.',
                style: TextStyle(fontSize: 18, color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // TODO: Implement real in-app purchase flow for monthly plan
                await paywall.upgradeToPremium(); // Simula a compra
                context.go('/categories');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Assinar Mensal - R\$ 12,90',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                // TODO: Implement real in-app purchase flow for annual plan
                await paywall.upgradeToPremium(); // Simula a compra
                context.go('/categories');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Assinar Anual - R\$ 79,90 (Economize 48%)',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            if (!paywall.isPremium) // Show trial option if not premium
              TextButton(
                onPressed: () async {
                  await paywall.startPremiumTrial();
                  context.go('/categories');
                },
                child: const Text(
                  'Experimente 7 Dias Grátis',
                  style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                ),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.go('/categories'),
              child: const Text(
                'Voltar',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'O que nossos usuários dizem:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            _buildSocialProof(
                '"Este aplicativo mudou minhas noites de sono!" - Maria S.'),
            _buildSocialProof(
                '"Meditações incríveis, me sinto muito mais calma." - João P.'),
            _buildSocialProof(
                '"+100 mil relaxaram com nosso app" - Selo de Qualidade'),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBenefit(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.greenAccent, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProof(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey[300]),
        textAlign: TextAlign.center,
      ),
    );
  }
}


