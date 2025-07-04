import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sona/utils/ad_config.dart';

class PaywallProvider extends ChangeNotifier {
  int _dailyPlayCount = 0;
  bool _isPremium = false;
  int _rewardedAdsWatched = 0;
  DateTime? _lastRewardedAdDate;

  int get dailyPlayCount => _dailyPlayCount;
  bool get isPremium => _isPremium;
  int get rewardedAdsWatched => _rewardedAdsWatched;
  
  // Calcula quantas reproduções gratuitas restam
  int get remainingFreePlays {
    if (_isPremium) return -1; // Ilimitado para premium
    return (AdConfig.maxDailyPlaysWithoutAds - _dailyPlayCount).clamp(0, AdConfig.maxDailyPlaysWithoutAds);
  }

  // Verifica se pode reproduzir sem anúncio
  bool get canPlayWithoutAd {
    return _isPremium || _dailyPlayCount < AdConfig.maxDailyPlaysWithoutAds;
  }

  set dailyPlayCount(int count) {
    _dailyPlayCount = count;
    notifyListeners();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyPlayCount = prefs.getInt('dailyPlayCount') ?? 0;
    _isPremium = prefs.getBool('isPremium') ?? false;
    _rewardedAdsWatched = prefs.getInt('rewardedAdsWatched') ?? 0;
    
    final lastRewardedAdDateString = prefs.getString('lastRewardedAdDate');
    if (lastRewardedAdDateString != null) {
      _lastRewardedAdDate = DateTime.parse(lastRewardedAdDateString);
    }

    final lastDate = prefs.getString('lastPlayDate');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    // Reset diário dos contadores
    if (lastDate != today) {
      _dailyPlayCount = 0;
      _rewardedAdsWatched = 0;
      _lastRewardedAdDate = null;
      
      await prefs.setInt('dailyPlayCount', 0);
      await prefs.setInt('rewardedAdsWatched', 0);
      await prefs.remove('lastRewardedAdDate');
      await prefs.setString('lastPlayDate', today);
    }

    notifyListeners();
  }

  Future<bool> registerPlay() async {
    if (_isPremium) return true;

    _dailyPlayCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyPlayCount', _dailyPlayCount);
    
    notifyListeners();
    return _dailyPlayCount <= AdConfig.maxDailyPlaysWithoutAds;
  }

  Future<void> registerRewardedAdWatched() async {
    _rewardedAdsWatched++;
    _lastRewardedAdDate = DateTime.now();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rewardedAdsWatched', _rewardedAdsWatched);
    await prefs.setString('lastRewardedAdDate', _lastRewardedAdDate!.toIso8601String());
    
    // Reset do contador de reproduções após assistir anúncio
    _dailyPlayCount = 0;
    await prefs.setInt('dailyPlayCount', 0);
    
    notifyListeners();
  }

  Future<void> upgradeToPremium() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', true);
    notifyListeners();
  }

  Future<void> downgradeToPremium() async {
    _isPremium = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', false);
    notifyListeners();
  }

  // Método para verificar se o usuário pode baixar conteúdo
  bool canDownloadContent() {
    return _isPremium; // Apenas usuários premium podem baixar
  }

  // Método para verificar se deve mostrar banner
  bool shouldShowBanner() {
    return !_isPremium;
  }

  // Método para obter status do usuário como string
  String getUserStatusText() {
    if (_isPremium) {
      return 'Premium';
    } else {
      return 'Gratuito ($remainingFreePlays reproduções restantes)';
    }
  }
}
