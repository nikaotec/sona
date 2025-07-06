import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/subscription_provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isYearlySelected = true; // Anual selecionado por padrão

  @override
  void initState() {
    super.initState();
    
    // Configuração das animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Inicia a animação
    _animationController.forward();
    
    // Inicializa o provider de assinatura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      if (!subscriptionProvider.isInitialized) {
        subscriptionProvider.initialize();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          return SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header com botão de fechar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 40),
                          const Text(
                            'Sona Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => context.go('/categories'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Ícone principal com animação
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6B73FF), Color(0xFF9644FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(60),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6B73FF).withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.diamond,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Título principal
                      const Text(
                        'Desbloqueie Todo o\nPotencial do Sona',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtítulo
                      const Text(
                        'Acesso ilimitado a todos os áudios premium,\nsem anúncios e com downloads offline.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Lista de benefícios
                      _buildBenefitsList(),
                      
                      const SizedBox(height: 40),
                      
                      // Seletor de planos
                      _buildPlanSelector(subscriptionProvider),
                      
                      const SizedBox(height: 32),
                      
                      // Botão de assinatura
                      _buildSubscribeButton(subscriptionProvider),
                      
                      const SizedBox(height: 16),
                      
                      // Botão de restaurar compras
                      _buildRestoreButton(subscriptionProvider),
                      
                      const SizedBox(height: 24),
                      
                      // Termos e condições
                      const Text(
                        'Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade. A assinatura será renovada automaticamente.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      // Indicador de carregamento
                      if (subscriptionProvider.isLoading) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(
                          color: Color(0xFF6B73FF),
                        ),
                      ],
                      
                      // Mensagem de erro
                      if (subscriptionProvider.errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            subscriptionProvider.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {
        'icon': Icons.all_inclusive,
        'title': 'Acesso Ilimitado',
        'description': 'Ouça quantos áudios quiser, sem limites diários',
      },
      {
        'icon': Icons.download_for_offline,
        'title': 'Downloads Offline',
        'description': 'Baixe seus áudios favoritos para ouvir offline',
      },
      {
        'icon': Icons.block,
        'title': 'Sem Anúncios',
        'description': 'Experiência completamente livre de interrupções',
      },
      {
        'icon': Icons.library_music,
        'title': 'Biblioteca Premium',
        'description': 'Acesso exclusivo a conteúdos premium',
      },
    ];

    return Column(
      children: benefits.map((benefit) => _buildBenefitItem(
        icon: benefit['icon'] as IconData,
        title: benefit['title'] as String,
        description: benefit['description'] as String,
      )).toList(),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6B73FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(SubscriptionProvider subscriptionProvider) {
    final monthlyProduct = subscriptionProvider.monthlyProduct;
    final yearlyProduct = subscriptionProvider.yearlyProduct;
    
    if (monthlyProduct == null || yearlyProduct == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Carregando planos...',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        // Plano Anual
        GestureDetector(
          onTap: () => setState(() => _isYearlySelected = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _isYearlySelected 
                ? const LinearGradient(
                    colors: [Color(0xFF6B73FF), Color(0xFF9644FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
              color: _isYearlySelected ? null : const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isYearlySelected 
                  ? Colors.transparent 
                  : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isYearlySelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Plano Anual',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subscriptionProvider.getYearlySavings(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        yearlyProduct.price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'R\$ ${(yearlyProduct.rawPrice / 12).toStringAsFixed(2)}/mês',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Plano Mensal
        GestureDetector(
          onTap: () => setState(() => _isYearlySelected = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: !_isYearlySelected 
                ? const Color(0xFF6B73FF) 
                : const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !_isYearlySelected 
                  ? Colors.transparent 
                  : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  !_isYearlySelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plano Mensal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthlyProduct.price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Renovação mensal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(SubscriptionProvider subscriptionProvider) {
    final selectedProduct = _isYearlySelected 
      ? subscriptionProvider.yearlyProduct 
      : subscriptionProvider.monthlyProduct;
    
    if (selectedProduct == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: subscriptionProvider.isLoading 
          ? null 
          : () => _handleSubscribe(subscriptionProvider, selectedProduct),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A2E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: subscriptionProvider.isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF1A1A2E),
                strokeWidth: 2,
              ),
            )
          : Text(
              'Assinar ${_isYearlySelected ? "Anual" : "Mensal"} - ${selectedProduct.price}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _buildRestoreButton(SubscriptionProvider subscriptionProvider) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: subscriptionProvider.isLoading 
          ? null 
          : () => subscriptionProvider.restorePurchases(),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey,
        ),
        child: const Text(
          'Restaurar Compras',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _handleSubscribe(SubscriptionProvider subscriptionProvider, ProductDetails product) async {
    try {
      await subscriptionProvider.purchaseSubscription(product);
      
      // Se a compra foi bem-sucedida, navega de volta
      if (subscriptionProvider.hasActiveSubscription && mounted) {
        context.go('/categories');
        
        // Mostra mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assinatura ativada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar assinatura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

