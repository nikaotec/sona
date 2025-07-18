import 'package:sona/model/audio_model.dart';

class MixModel {
  final String id;
  final String name;
  final List<AudioModel> audios;
  final DateTime createdAt;
  final DateTime? lastPlayedAt;
  final String? description;
  final String? coverImageUrl;

  MixModel({
    required this.id,
    required this.name,
    required this.audios,
    required this.createdAt,
    this.lastPlayedAt,
    this.description,
    this.coverImageUrl,
  });

  // Duração total do mix
  Duration get totalDuration {
    return audios.fold(
      Duration.zero,
      (total, audio) => total + audio.duration,
    );
  }

  // Número de faixas
  int get trackCount => audios.length;

  // Verifica se o mix está vazio
  bool get isEmpty => audios.isEmpty;

  // Verifica se contém uma música específica
  bool containsAudio(AudioModel audio) {
    return audios.any((a) => a.id == audio.id);
  }

  // Cria uma cópia do mix com modificações
  MixModel copyWith({
    String? id,
    String? name,
    List<AudioModel>? audios,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    String? description,
    String? coverImageUrl,
  }) {
    return MixModel(
      id: id ?? this.id,
      name: name ?? this.name,
      audios: audios ?? this.audios,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  // Converte para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'audios': audios.map((audio) => audio.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastPlayedAt': lastPlayedAt?.millisecondsSinceEpoch,
      'description': description,
      'coverImageUrl': coverImageUrl,
    };
  }

  // Cria MixModel a partir de Map
  factory MixModel.fromMap(Map<String, dynamic> map) {
    return MixModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      audios: (map['audios'] as List<dynamic>?)
              ?.map((audioMap) => AudioModel.fromMap(audioMap))
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastPlayedAt: map['lastPlayedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPlayedAt'])
          : null,
      description: map['description'],
      coverImageUrl: map['coverImageUrl'],
    );
  }

  @override
  String toString() {
    return 'MixModel(id: $id, name: $name, trackCount: $trackCount, duration: $totalDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MixModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
