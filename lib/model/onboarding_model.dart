class OnboardingData {
  final String objetivo;
  final String humor;
  final String estilo;
  final String horario;
  final String? recomendacaoIA;

  OnboardingData({
    required this.objetivo,
    required this.humor,
    required this.estilo,
    required this.horario,
    this.recomendacaoIA,
  });

  Map<String, dynamic> toJson() {
    return {
      'objetivo': objetivo,
      'humor': humor,
      'estilo': estilo,
      'horario': horario,
      'recomendacaoIA': recomendacaoIA,
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      objetivo: json['objetivo'],
      humor: json['humor'],
      estilo: json['estilo'],
      horario: json['horario'],
      recomendacaoIA: json['recomendacaoIA'],
    );
  }

  OnboardingData copyWith({
    String? objetivo,
    String? humor,
    String? estilo,
    String? horario,
    String? recomendacaoIA,
  }) {
    return OnboardingData(
      objetivo: objetivo ?? this.objetivo,
      humor: humor ?? this.humor,
      estilo: estilo ?? this.estilo,
      horario: horario ?? this.horario,
      recomendacaoIA: recomendacaoIA ?? this.recomendacaoIA,
    );
  }
}

class OnboardingOption {
  final String id;
  final String title;
  final String description;

  OnboardingOption({
    required this.id,
    required this.title,
    required this.description,
  });
}

class OnboardingStep {
  final String title;
  final String subtitle;
  final List<OnboardingOption> options;

  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.options,
  });
}

