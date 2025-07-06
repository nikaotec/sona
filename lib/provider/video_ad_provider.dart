import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sona/service/video_ad_service.dart';
import 'package:sona/provider/subscription_provider.dart';

class VideoAdProvider extends ChangeNotifier {
  final VideoAdService _videoAdService = VideoAdService();
  final SubscriptionProvider _subscriptionProvider;
  
  // Estado dos anúncios
  bool _isAdLoading = false;
  bool _isAdShowing = false;
  String? _lastPlayedAudioId;
  bool _hasShownAdInCurrentSession = false;
  int _adsWatchedToday = 0;
  DateTime? _lastAdDate;
  
  // Configurações
  static const int maxAdsPerDay = 10;
  static const int minTimeBetweenAds = 30; // segundos

  VideoAdProvider(this._subscriptionProvider) {
    _subscriptionProvider.addListener(_onSubscriptionChanged);
    _loadAdData();
    _videoAdService.loadRewardedInterstitialAd();
  }

  // Getters
  bool get isAdLoading => _isAdLoading;
  bool get isAdShowing => _isAdShowing;
  bool get hasShownAdInCurrentSession => _hasShownAdInCurrentSession;
  int get adsWatchedToday => _adsWatchedToday;
  int get remainingAdsToday => (maxAdsPerDay - _adsWatchedToday).clamp(0, maxAdsPerDay);

  /// Carrega dados dos anúncios do armazenamento local
  Future<void> _loadAdData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adsWatchedToday = prefs.getInt('ads_watched_today') ?? 0;
      
      final lastAdDateString = prefs.getString('last_ad_date');
      if (lastAdDateString != null) {
        _lastAdDate = DateTime.parse(lastAdDateString);
      }

      // Reset diário
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final savedDate = prefs.getString('last_ad_reset_date');
      
      if (savedDate != today) {
        _adsWatchedToday = 0;
        _hasShownAdInCurrentSession = false;
        await prefs.setInt('ads_watched_today', 0);
        await prefs.setBool('has_shown_ad_in_session', false);
        await prefs.setString('last_ad_reset_date', today);
      } else {
        _hasShownAdInCurrentSession = prefs.getBool('has_shown_ad_in_session') ?? false;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados dos anúncios: $e');
    }
  }

  /// Salva dados dos anúncios no armazenamento local
  Future<void> _saveAdData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ads_watched_today', _adsWatchedToday);
      await prefs.setBool('has_shown_ad_in_session', _hasShownAdInCurrentSession);
      
      if (_lastAdDate != null) {
        await prefs.setString('last_ad_date', _lastAdDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Erro ao salvar dados dos anúncios: $e');
    }
  }

  /// Verifica se deve mostrar anúncio baseado nas regras de negócio
  bool shouldShowVideoAd(String audioId) {
    // Se é premium, nunca mostra anúncio
    if (_subscriptionProvider.hasActiveSubscription) {
      return false;
    }

    // Se atingiu o limite diário de anúncios
    if (_adsWatchedToday >= maxAdsPerDay) {
      return false;
    }

    // Se já está mostrando um anúncio
    if (_isAdShowing) {
      return false;
    }

    // Primeira reprodução da sessão
    if (!_hasShownAdInCurrentSession) {
      return true;
    }

    // Música diferente da anterior
    if (_lastPlayedAudioId != null && _lastPlayedAudioId != audioId) {
      // Verifica tempo mínimo entre anúncios
      if (_lastAdDate != null) {
        final timeSinceLastAd = DateTime.now().difference(_lastAdDate!);
        if (timeSinceLastAd.inSeconds < minTimeBetweenAds) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  /// Mostra anúncio em vídeo se necessário
  Future<bool> showVideoAdIfNeeded(
    String audioId, {
    required VoidCallback onAdCompleted,
    required Function(String) onAdFailed,
    VoidCallback? onUserEarnedReward,
  }) async {
    if (!shouldShowVideoAd(audioId)) {
      onAdCompleted();
      return false;
    }

    _setAdShowing(true);
    _lastPlayedAudioId = audioId;

    try {
      _videoAdService.showVideoAd(
        onAdDismissed: () {
          _onAdCompleted();
          onAdCompleted();
        },
        onAdFailedToLoadOrShow: (error) {
          _setAdShowing(false);
          onAdFailed(error);
        },
        onUserEarnedRewardCallback: () {
          _onUserEarnedReward();
          onUserEarnedReward?.call();
        },
      );
      return true;
    } catch (e) {
      _setAdShowing(false);
      onAdFailed('Erro ao exibir anúncio: $e');
      return false;
    }
  }

  /// Callback quando anúncio é completado
  void _onAdCompleted() {
    _setAdShowing(false);
    _hasShownAdInCurrentSession = true;
    _lastAdDate = DateTime.now();
    _saveAdData();
  }

  /// Callback quando usuário ganha recompensa
  void _onUserEarnedReward() {
    _adsWatchedToday++;
    _saveAdData();
  }

  /// Pré-carrega próximo anúncio
  void preloadNextAd() {
    if (!_subscriptionProvider.hasActiveSubscription && 
        _adsWatchedToday < maxAdsPerDay) {
      _videoAdService.loadRewardedInterstitialAd();
    }
  }

  /// Força reset da sessão (útil para testes)
  Future<void> resetSession() async {
    _hasShownAdInCurrentSession = false;
    _lastPlayedAudioId = null;
    await _saveAdData();
    notifyListeners();
  }

  /// Reset diário (chamado automaticamente)
  Future<void> resetDaily() async {
    _adsWatchedToday = 0;
    _hasShownAdInCurrentSession = false;
    _lastPlayedAudioId = null;
    _lastAdDate = null;
    await _saveAdData();
    notifyListeners();
  }

  /// Obtém estatísticas dos anúncios
  Map<String, dynamic> getAdStats() {
    return {
      'adsWatchedToday': _adsWatchedToday,
      'remainingAdsToday': remainingAdsToday,
      'hasShownAdInSession': _hasShownAdInCurrentSession,
      'lastAdDate': _lastAdDate?.toIso8601String(),
      'isPremium': _subscriptionProvider.hasActiveSubscription,
    };
  }

  /// Simula assistir anúncio (para testes)
  Future<void> simulateAdWatched(String audioId) async {
    if (kDebugMode) {
      _lastPlayedAudioId = audioId;
      _hasShownAdInCurrentSession = true;
      _adsWatchedToday++;
      _lastAdDate = DateTime.now();
      await _saveAdData();
      notifyListeners();
    }
  }

  // Métodos auxiliares
  void _setAdShowing(bool showing) {
    _isAdShowing = showing;
    notifyListeners();
  }

  void _onSubscriptionChanged() {
    // Se virou premium, para de carregar anúncios
    if (_subscriptionProvider.hasActiveSubscription) {
      _setAdShowing(false);
    } else {
      // Se perdeu premium, recarrega anúncios
      preloadNextAd();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscriptionProvider.removeListener(_onSubscriptionChanged);
    super.dispose();
  }
}

