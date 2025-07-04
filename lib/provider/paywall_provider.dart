import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PaywallProvider extends ChangeNotifier {
  int _dailyPlayCount = 0;
  bool _isPremium = false;
  DateTime? _premiumTrialEndDate;

  int get dailyPlayCount => _dailyPlayCount;
  bool get isPremium => _isPremium || (_premiumTrialEndDate != null && _premiumTrialEndDate!.isAfter(DateTime.now()));

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyPlayCount = prefs.getInt('dailyPlayCount') ?? 0;
    _isPremium = prefs.getBool('isPremium') ?? false;
    final trialEndDateMillis = prefs.getInt('premiumTrialEndDate');
    if (trialEndDateMillis != null) {
      _premiumTrialEndDate = DateTime.fromMillisecondsSinceEpoch(trialEndDateMillis);
    }

    final lastDate = prefs.getString('lastPlayDate');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDate != today) {
      _dailyPlayCount = 0;
      prefs.setInt('dailyPlayCount', 0);
      prefs.setString('lastPlayDate', today);
    }

    notifyListeners();
  }

  Future<bool> registerPlay() async {
    if (isPremium) return true;
    if (_dailyPlayCount >= 3) return false;

    _dailyPlayCount++;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('dailyPlayCount', _dailyPlayCount);
    notifyListeners();
    return true;
  }

  Future<void> upgradeToPremium() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isPremium', true);
    _premiumTrialEndDate = null; // End trial if user upgrades
    prefs.remove('premiumTrialEndDate');
    notifyListeners();
  }

  Future<void> startPremiumTrial() async {
    _premiumTrialEndDate = DateTime.now().add(const Duration(days: 7));
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('premiumTrialEndDate', _premiumTrialEndDate!.millisecondsSinceEpoch);
    notifyListeners();
  }

  // In-app purchase related methods (placeholders for now)
  Future<void> initInAppPurchase() async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      // The store is not available
      return;
    }
    // TODO: Implement product fetching and purchase flow
  }

  void handlePurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      // Handle successful purchase
      upgradeToPremium();
      InAppPurchase.instance.completePurchase(purchaseDetails);
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      // Handle purchase error
      print('Purchase error: ${purchaseDetails.error}');
    }
  }
}


