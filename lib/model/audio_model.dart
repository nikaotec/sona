class AudioModel {
  final String id;
  final String title;
  final String url;
  final String category;
  final Duration duration;
  final bool isPremium;
  final double volume; // Adicionando propriedade de volume

  AudioModel({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    required this.duration,
    this.isPremium = false,
    this.volume = 1.0, // Valor padrão para volume
  });

  factory AudioModel.fromMap(Map<String, dynamic> map) {
    return AudioModel(
      id: map["id"],
      title: map["title"],
      url: map["url"],
      category: map["category"],
      duration: Duration(seconds: map["duration"]),
      isPremium: map["isPremium"] ?? false,
      volume: map["volume"] ?? 1.0, // Carregar volume do mapa
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "url": url,
      "category": category,
      "duration": duration.inSeconds,
      "isPremium": isPremium,
      "volume": volume, // Salvar volume no mapa
    };
  }

  AudioModel copyWith({
    String? id,
    String? title,
    String? url,
    String? category,
    Duration? duration,
    bool? isPremium,
    double? volume,
  }) {
    return AudioModel(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      isPremium: isPremium ?? this.isPremium,
      volume: volume ?? this.volume,
    );
  }
}