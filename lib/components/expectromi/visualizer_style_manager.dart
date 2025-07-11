import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'circular_music_visualizer.dart';

class VisualizerStyleManager {
  static const List<VisualizerStyleConfig> _styles = [
    VisualizerStyleConfig(
      style: VisualizerStyle.spectrum,
      name: 'Espectro',
      description: 'Visualizador clássico com barras de frequência',
      primaryColor: Color(0xFF00D4FF),
      secondaryColor: Color(0xFF5B73FF),
      category: VisualizerCategory.energetic,
    ),
    VisualizerStyleConfig(
      style: VisualizerStyle.pulse,
      name: 'Pulso',
      description: 'Círculos pulsantes suaves e relaxantes',
      primaryColor: Color(0xFF6B73FF),
      secondaryColor: Color(0xFF9644FF),
      category: VisualizerCategory.relaxing,
    ),
    VisualizerStyleConfig(
      style: VisualizerStyle.wave,
      name: 'Ondas',
      description: 'Ondas circulares fluidas e hipnotizantes',
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF3F51B5),
      category: VisualizerCategory.hypnotic,
    ),
    VisualizerStyleConfig(
      style: VisualizerStyle.particle,
      name: 'Partículas',
      description: 'Partículas dançantes em movimento orbital',
      primaryColor: Color(0xFFFF6B6B),
      secondaryColor: Color(0xFFFFE66D),
      category: VisualizerCategory.energetic,
    ),
    VisualizerStyleConfig(
      style: VisualizerStyle.ripple,
      name: 'Ondulações',
      description: 'Ondulações concêntricas relaxantes',
      primaryColor: Color(0xFF4ECDC4),
      secondaryColor: Color(0xFF44A08D),
      category: VisualizerCategory.relaxing,
    ),
    VisualizerStyleConfig(
      style: VisualizerStyle.galaxy,
      name: 'Galáxia',
      description: 'Espiral galáctica com estrelas cintilantes',
      primaryColor: Color(0xFF667EEA),
      secondaryColor: Color(0xFF764BA2),
      category: VisualizerCategory.hypnotic,
    ),
    VisualizerStyleConfig(
      style: VisualizerStyle.mandala,
      name: 'Mandala',
      description: 'Padrões geométricos meditativos',
      primaryColor: Color(0xFFFF9A9E),
      secondaryColor: Color(0xFFFECFEF),
      category: VisualizerCategory.meditative,
    ),
    VisualizerStyleConfig(
      style: VisualizerStyle.spiral,
      name: 'Espiral',
      description: 'Espirais hipnotizantes em movimento',
      primaryColor: Color(0xFFA8EDEA),
      secondaryColor: Color(0xFFFED6E3),
      category: VisualizerCategory.hypnotic,
    ),
    VisualizerStyleConfig(
      style: VisualizerStyle.sphere,
      name: 'Esfera',
      description: 'Esfera abstrata que reage ao ritmo da música',
      primaryColor: Color(0xFFFF00FF),
      secondaryColor: Color(0xFF00FFFF),
      category: VisualizerCategory.hypnotic,
    ),
  ];

  /// Retorna um estilo aleatório baseado na categoria da música
  static VisualizerStyleConfig getStyleForMusic({
    String? category,
    String? title,
    VisualizerCategory? preferredCategory,
  }) {
    List<VisualizerStyleConfig> candidateStyles = _styles;

    // Filtrar por categoria preferida se especificada
    if (preferredCategory != null) {
      candidateStyles = _styles
          .where((style) => style.category == preferredCategory)
          .toList();
    }
    // Ou filtrar baseado na categoria da música
    else if (category != null) {
      final musicCategory = _getMusicCategory(category, title);
      candidateStyles = _styles
          .where((style) => style.category == musicCategory)
          .toList();
    }

    // Se não encontrou estilos na categoria, usar todos
    if (candidateStyles.isEmpty) {
      candidateStyles = _styles;
    }

    // Retornar um estilo aleatório da lista filtrada
    final random = math.Random();
    return candidateStyles[random.nextInt(candidateStyles.length)];
  }

  /// Determina a categoria do visualizador baseado na música
  static VisualizerCategory _getMusicCategory(String? category, String? title) {
    if (category == null && title == null) {
      return VisualizerCategory.relaxing;
    }

    final categoryLower = category?.toLowerCase() ?? '';
    final titleLower = title?.toLowerCase() ?? '';
    final combined = '$categoryLower $titleLower';

    // Palavras-chave para diferentes categorias
    if (_containsAny(combined, [
      'meditation', 'meditação', 'relaxing', 'relaxante', 'calm', 'calmo',
      'peaceful', 'paz', 'tranquil', 'tranquilo', 'zen', 'mindfulness',
      'sleep', 'sono', 'rest', 'descanso'
    ])) {
      return VisualizerCategory.meditative;
    }

    if (_containsAny(combined, [
      'energetic', 'energético', 'upbeat', 'animado', 'dance', 'dança',
      'electronic', 'eletrônico', 'techno', 'house', 'trance', 'edm',
      'workout', 'exercise', 'exercício', 'gym', 'fitness'
    ])) {
      return VisualizerCategory.energetic;
    }

    if (_containsAny(combined, [
      'hypnotic', 'hipnótico', 'trance', 'ambient', 'atmospheric',
      'atmosférico', 'psychedelic', 'psicodélico', 'dreamy', 'sonhador',
      'ethereal', 'etéreo', 'mystical', 'místico'
    ])) {
      return VisualizerCategory.hypnotic;
    }

    // Padrão para música relaxante
    return VisualizerCategory.relaxing;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Retorna todos os estilos disponíveis
  static List<VisualizerStyleConfig> getAllStyles() => _styles;

  /// Retorna estilos por categoria
  static List<VisualizerStyleConfig> getStylesByCategory(
      VisualizerCategory category) {
    return _styles.where((style) => style.category == category).toList();
  }

  /// Retorna um estilo específico por tipo
  static VisualizerStyleConfig? getStyleByType(VisualizerStyle style) {
    try {
      return _styles.firstWhere((config) => config.style == style);
    } catch (e) {
      return null;
    }
  }

  /// Gera cores dinâmicas baseadas no tempo para criar variação
  static ColorPair getDynamicColors(VisualizerStyleConfig config) {
    final now = DateTime.now();
    final timeBasedHue = (now.millisecondsSinceEpoch / 10000) % 360;
    
    // Criar variações sutis das cores originais
    final primaryHSV = HSVColor.fromColor(config.primaryColor);
    final secondaryHSV = HSVColor.fromColor(config.secondaryColor);
    
    final newPrimary = primaryHSV.withHue((primaryHSV.hue + timeBasedHue * 0.1) % 360);
    final newSecondary = secondaryHSV.withHue((secondaryHSV.hue + timeBasedHue * 0.1) % 360);
    
    return ColorPair(
      primary: newPrimary.toColor(),
      secondary: newSecondary.toColor(),
    );
  }

  /// Retorna intensidade baseada no tipo de música
  static double getIntensityForMusic(String? category, String? title) {
    final musicCategory = _getMusicCategory(category, title);
    
    switch (musicCategory) {
      case VisualizerCategory.energetic:
        return 1.5;
      case VisualizerCategory.hypnotic:
        return 1.2;
      case VisualizerCategory.meditative:
        return 0.7;
      case VisualizerCategory.relaxing:
        return 1.0;
    }
  }
}

enum VisualizerCategory {
  energetic,
  relaxing,
  hypnotic,
  meditative,
}

class VisualizerStyleConfig {
  final VisualizerStyle style;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final VisualizerCategory category;

  const VisualizerStyleConfig({
    required this.style,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.category,
  });
}

class ColorPair {
  final Color primary;
  final Color secondary;

  const ColorPair({
    required this.primary,
    required this.secondary,
  });
}

/// Extension para facilitar o uso das categorias
extension VisualizerCategoryExtension on VisualizerCategory {
  String get displayName {
    switch (this) {
      case VisualizerCategory.energetic:
        return 'Energético';
      case VisualizerCategory.relaxing:
        return 'Relaxante';
      case VisualizerCategory.hypnotic:
        return 'Hipnotizante';
      case VisualizerCategory.meditative:
        return 'Meditativo';
    }
  }

  String get description {
    switch (this) {
      case VisualizerCategory.energetic:
        return 'Visuais dinâmicos e estimulantes';
      case VisualizerCategory.relaxing:
        return 'Animações suaves e calmantes';
      case VisualizerCategory.hypnotic:
        return 'Padrões hipnotizantes e envolventes';
      case VisualizerCategory.meditative:
        return 'Visuais contemplativos e zen';
    }
  }

  Color get accentColor {
    switch (this) {
      case VisualizerCategory.energetic:
        return const Color(0xFFFF6B6B);
      case VisualizerCategory.relaxing:
        return const Color(0xFF6B73FF);
      case VisualizerCategory.hypnotic:
        return const Color(0xFF667EEA);
      case VisualizerCategory.meditative:
        return const Color(0xFF4ECDC4);
    }
  }
}
