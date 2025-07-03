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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Você atingiu o limite diário de 3 áudios gratuitos.\nAssine para acesso ilimitado.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await paywall.upgradeToPremium(); // Simula a compra
                context.go('/categories');
              },
              child: const Text('Assinar - R\$ 9,90/mês'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go('/categories'),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
