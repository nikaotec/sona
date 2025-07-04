import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaywallProvider extends ChangeNotifier {
  int _dailyPlayCount = 0;
  bool _isPremium = false;

  int get dailyPlayCount => _dailyPlayCount;
  set dailyPlayCount(int count) {
    _dailyPlayCount = count;
    notifyListeners();
  }
  bool get isPremium => _isPremium;

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyPlayCount = prefs.getInt('dailyPlayCount') ?? 0;
    _isPremium = prefs.getBool('isPremium') ?? false;

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
    if (_isPremium) return true;
   

    _dailyPlayCount++;
     if (_dailyPlayCount >= 3) return false;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('dailyPlayCount', _dailyPlayCount);
    notifyListeners();
    return true;
  }

  Future<void> upgradeToPremium() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isPremium', true);
    notifyListeners();
  }
}
