import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sona/service/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  // Estado da assinatura
  bool _isLoading = false;
  bool _hasActiveSubscription = false;
  String? _activeSubscriptionId;
  String? _errorMessage;
  List<ProductDetails> _products = [];
  bool _isInitialized = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasActiveSubscription => _hasActiveSubscription;
  String? get activeSubscriptionId => _activeSubscriptionId;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;
  bool get isInitialized => _isInitialized;

  // Produtos específicos
  ProductDetails? get monthlyProduct => _subscriptionService.monthlyProduct;
  ProductDetails? get yearlyProduct => _subscriptionService.yearlyProduct;

  /// Inicializa o provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    
    try {
      // Configura callbacks do serviço
      _subscriptionService.onPurchaseUpdated = _onPurchaseUpdated;
      _subscriptionService.onPurchaseError = _onPurchaseError;
      _subscriptionService.onPurchaseSuccess = _onPurchaseSuccess;

      // Inicializa o serviço
      await _subscriptionService.initialize();
      
      // Carrega produtos
      _products = _subscriptionService.products;
      
      // Verifica assinatura ativa
      await _checkActiveSubscription();
      
      _isInitialized = true;
      _clearError();
      
      debugPrint('SubscriptionProvider inicializado com sucesso');
    } catch (e) {
      _setError('Erro ao inicializar assinaturas: $e');
      debugPrint('Erro ao inicializar SubscriptionProvider: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Compra uma assinatura
  Future<void> purchaseSubscription(ProductDetails product) async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      await _subscriptionService.buySubscription(product);
    } catch (e) {
      _setError('Erro ao processar compra: $e');
      _setLoading(false);
    }
  }

  /// Restaura compras anteriores
  Future<void> restorePurchases() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      await _subscriptionService.restorePurchases();
      await _checkActiveSubscription();
    } catch (e) {
      _setError('Erro ao restaurar compras: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Verifica se há uma assinatura ativa
  Future<void> _checkActiveSubscription() async {
    try {
      // Verifica no serviço
      final hasActive = _subscriptionService.hasActiveSubscription();
      final activeSubscription = _subscriptionService.getActiveSubscription();
      
      _hasActiveSubscription = hasActive;
      _activeSubscriptionId = activeSubscription?.productID;
      
      // Salva o estado localmente
      await _saveSubscriptionState();
      
      debugPrint('Assinatura ativa: $_hasActiveSubscription');
      if (_activeSubscriptionId != null) {
        debugPrint('ID da assinatura: $_activeSubscriptionId');
      }
    } catch (e) {
      debugPrint('Erro ao verificar assinatura ativa: $e');
    }
  }

  /// Salva o estado da assinatura localmente
  Future<void> _saveSubscriptionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_active_subscription', _hasActiveSubscription);
      if (_activeSubscriptionId != null) {
        await prefs.setString('active_subscription_id', _activeSubscriptionId!);
      } else {
        await prefs.remove('active_subscription_id');
      }
    } catch (e) {
      debugPrint('Erro ao salvar estado da assinatura: $e');
    }
  }

  /// Carrega o estado da assinatura do armazenamento local
  Future<void> loadSubscriptionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasActiveSubscription = prefs.getBool('has_active_subscription') ?? false;
      _activeSubscriptionId = prefs.getString('active_subscription_id');
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar estado da assinatura: $e');
    }
  }

  /// Callback para atualizações de compra
  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    debugPrint('Compras atualizadas: ${purchases.length}');
    _checkActiveSubscription();
  }

  /// Callback para erros de compra
  void _onPurchaseError(String error) {
    _setError(error);
    _setLoading(false);
  }

  /// Callback para compra bem-sucedida
  void _onPurchaseSuccess() {
    _setLoading(false);
    _clearError();
    _checkActiveSubscription();
  }

  /// Obtém informações de preço formatadas
  String getFormattedPrice(ProductDetails product) {
    return product.price;
  }

  /// Obtém informações detalhadas sobre um produto
  Map<String, dynamic> getProductInfo(ProductDetails product) {
    return _subscriptionService.getPriceInfo(product);
  }

  /// Calcula economia anual
  String getYearlySavings() {
    final monthly = monthlyProduct;
    final yearly = yearlyProduct;
    
    if (monthly == null || yearly == null) return '';
    
    try {
      final monthlyPrice = monthly.rawPrice;
      final yearlyPrice = yearly.rawPrice;
      final monthlyYearTotal = monthlyPrice * 12;
      final savings = monthlyYearTotal - yearlyPrice;
      final savingsPercentage = (savings / monthlyYearTotal * 100).round();
      
      return 'Economize $savingsPercentage%';
    } catch (e) {
      return '';
    }
  }

  /// Obtém o período da assinatura
  String getSubscriptionPeriod(ProductDetails product) {
    if (product.id == SubscriptionService.monthlySubscriptionId) {
      return 'Mensal';
    } else if (product.id == SubscriptionService.yearlySubscriptionId) {
      return 'Anual';
    }
    return '';
  }

  /// Verifica se é uma assinatura mensal
  bool isMonthlySubscription(String productId) {
    return productId == SubscriptionService.monthlySubscriptionId;
  }

  /// Verifica se é uma assinatura anual
  bool isYearlySubscription(String productId) {
    return productId == SubscriptionService.yearlySubscriptionId;
  }

  // Métodos auxiliares para gerenciar estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }
}

