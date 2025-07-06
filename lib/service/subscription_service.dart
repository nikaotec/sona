import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // IDs dos produtos de assinatura
  static const String monthlySubscriptionId = 'sona_premium_monthly';
  static const String yearlySubscriptionId = 'sona_premium_yearly';
  
  static const Set<String> _productIds = {
    monthlySubscriptionId,
    yearlySubscriptionId,
  };

  // Estado dos produtos
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;

  // Getters
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  String? get queryProductError => _queryProductError;

  // Callbacks
  Function(List<PurchaseDetails>)? onPurchaseUpdated;
  Function(String)? onPurchaseError;
  Function()? onPurchaseSuccess;

  /// Inicializa o serviço de assinatura
  Future<void> initialize() async {
    try {
      // Verifica se as compras in-app estão disponíveis
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        debugPrint('In-app purchases não estão disponíveis');
        return;
      }

      // Configura o listener para atualizações de compra
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () => _subscription.cancel(),
        onError: (error) => debugPrint('Erro no stream de compras: $error'),
      );

      // Carrega os produtos disponíveis
      await loadProducts();

      // Restaura compras anteriores
      await restorePurchases();

      debugPrint('SubscriptionService inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar SubscriptionService: $e');
    }
  }

  /// Carrega os produtos de assinatura do Google Play / App Store
  Future<void> loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Produtos não encontrados: ${response.notFoundIDs}');
      }
      
      if (response.error != null) {
        _queryProductError = response.error!.message;
        debugPrint('Erro ao carregar produtos: ${response.error!.message}');
        return;
      }

      _products = response.productDetails;
      _queryProductError = null;
      
      debugPrint('Produtos carregados: ${_products.length}');
      for (var product in _products) {
        debugPrint('Produto: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e) {
      _queryProductError = 'Erro ao carregar produtos: $e';
      debugPrint(_queryProductError);
    }
  }

  /// Obtém o produto mensal
  ProductDetails? get monthlyProduct {
    try {
      return _products.firstWhere((product) => product.id == monthlySubscriptionId);
    } catch (e) {
      return null;
    }
  }

  /// Obtém o produto anual
  ProductDetails? get yearlyProduct {
    try {
      return _products.firstWhere((product) => product.id == yearlySubscriptionId);
    } catch (e) {
      return null;
    }
  }

  /// Inicia a compra de uma assinatura
  Future<void> buySubscription(ProductDetails product) async {
    if (!_isAvailable) {
      onPurchaseError?.call('Compras in-app não estão disponíveis');
      return;
    }

    if (_purchasePending) {
      onPurchaseError?.call('Uma compra já está em andamento');
      return;
    }

    try {
      _purchasePending = true;
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _purchasePending = false;
      onPurchaseError?.call('Erro ao iniciar compra: $e');
      debugPrint('Erro ao comprar produto: $e');
    }
  }

  /// Restaura compras anteriores
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Compras restauradas');
    } catch (e) {
      debugPrint('Erro ao restaurar compras: $e');
    }
  }

  /// Verifica se o usuário tem uma assinatura ativa
  bool hasActiveSubscription() {
    for (var purchase in _purchases) {
      if (_productIds.contains(purchase.productID) && 
          purchase.status == PurchaseStatus.purchased) {
        return true;
      }
    }
    return false;
  }

  /// Obtém a assinatura ativa atual
  PurchaseDetails? getActiveSubscription() {
    for (var purchase in _purchases) {
      if (_productIds.contains(purchase.productID) && 
          purchase.status == PurchaseStatus.purchased) {
        return purchase;
      }
    }
    return null;
  }

  /// Callback para atualizações de compra
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
    
    onPurchaseUpdated?.call(purchaseDetailsList);
  }

  /// Processa uma compra individual
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      // Verifica a compra no servidor (implementar validação)
      bool valid = await _verifyPurchase(purchaseDetails);
      
      if (valid) {
        // Atualiza o estado local
        _purchases.add(purchaseDetails);
        onPurchaseSuccess?.call();
        debugPrint('Compra realizada com sucesso: ${purchaseDetails.productID}');
      } else {
        debugPrint('Compra inválida: ${purchaseDetails.productID}');
        onPurchaseError?.call('Compra inválida');
      }
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint('Erro na compra: ${purchaseDetails.error}');
      onPurchaseError?.call(purchaseDetails.error?.message ?? 'Erro desconhecido');
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      debugPrint('Compra cancelada pelo usuário');
      onPurchaseError?.call('Compra cancelada');
    }

    // Finaliza a compra pendente
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
    
    _purchasePending = false;
  }

  /// Verifica a validade da compra (implementar validação no servidor)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: Implementar validação no servidor
    // Por enquanto, retorna true para todas as compras
    return true;
  }

  /// Obtém informações detalhadas sobre preços regionais
  Map<String, dynamic> getPriceInfo(ProductDetails product) {
    Map<String, dynamic> priceInfo = {
      'id': product.id,
      'title': product.title,
      'description': product.description,
      'price': product.price,
      'rawPrice': product.rawPrice,
      'currencyCode': product.currencyCode,
      'currencySymbol': product.currencySymbol,
    };

    // Informações básicas disponíveis em todas as plataformas
    return priceInfo;
  }

  /// Dispose do serviço
  void dispose() {
    _subscription.cancel();
  }
}

