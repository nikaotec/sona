import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../model/onboarding_model.dart';
import '../service/openai_service.dart';

class OnboardingProvider extends ChangeNotifier {
  OnboardingData? _onboardingData;
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  OnboardingData? get onboardingData => _onboardingData;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

   // Adicionando getters para as propriedades do onboarding
  String get objetivo => _onboardingData?.objetivo ?? '';
  String get humor => _onboardingData?.humor ?? '';
  String get estilo => _onboardingData?.estilo ?? '';
  String get horario => _onboardingData?.horario ?? '';

  final OpenAIService _openAIService = OpenAIService();

  void setObjetivo(String objetivo) {
    _onboardingData = (_onboardingData ?? OnboardingData(
      objetivo: '',
      humor: '',
      estilo: '',
      horario: '',
    )).copyWith(objetivo: objetivo);
    notifyListeners();
  }

  void setHumor(String humor) {
    _onboardingData = _onboardingData!.copyWith(humor: humor);
    notifyListeners();
  }

  void setEstilo(String estilo) {
    _onboardingData = _onboardingData!.copyWith(estilo: estilo);
    notifyListeners();
  }

  void setHorario(String horario) {
    _onboardingData = _onboardingData!.copyWith(horario: horario);
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 5) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  Future<void> generateRecommendation() async {
    if (_onboardingData == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final recommendation = await _openAIService.generateRecommendation(_onboardingData!);
      _onboardingData = _onboardingData!.copyWith(recomendacaoIA: recommendation);
      await _saveOnboardingData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao gerar recomendação: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveOnboardingData() async {
    if (_onboardingData == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_onboardingData!.toJson());
    await prefs.setString('onboarding_data', jsonString);
  }

  Future<void> loadOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('onboarding_data');
    
    if (jsonString != null) {
      final jsonData = json.decode(jsonString);
      _onboardingData = OnboardingData.fromJson(jsonData);
      notifyListeners();
    }
  }

  void resetOnboarding() {
    _onboardingData = null;
    _currentStep = 0;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  bool get isOnboardingComplete => _onboardingData?.recomendacaoIA != null;
}

