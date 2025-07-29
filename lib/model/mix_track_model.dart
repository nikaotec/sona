import 'package:just_audio/just_audio.dart';
import 'package:sona/model/audio_model.dart';

class MixTrackModel {
  final String id;
  final AudioModel audio;
  final AudioPlayer player;
  double volume;
  bool isPlaying;
  bool isLoaded;
  bool isMuted;
  DateTime addedAt;

  MixTrackModel({
    required this.id,
    required this.audio,
    required this.player,
    this.volume = 0.7,
    this.isPlaying = false,
    this.isLoaded = false,
    this.isMuted = false,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  // Converter para JSON para salvamento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audio': audio.toMap(),
      'volume': volume,
      'isPlaying': isPlaying,
      'isMuted': isMuted,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Criar a partir de JSON
  static MixTrackModel fromJson(Map<String, dynamic> json) {
    return MixTrackModel(
      id: json['id'] as String,
      audio: AudioModel.fromMap(json['audio'] as Map<String, dynamic>),
      player: AudioPlayer(), // Novo player será criado
      volume: (json['volume'] as num?)?.toDouble() ?? 0.7,
      isPlaying: json['isPlaying'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  // Copiar com modificações
  MixTrackModel copyWith({
    String? id,
    AudioModel? audio,
    AudioPlayer? player,
    double? volume,
    bool? isPlaying,
    bool? isLoaded,
    bool? isMuted,
    DateTime? addedAt,
  }) {
    return MixTrackModel(
      id: id ?? this.id,
      audio: audio ?? this.audio,
      player: player ?? this.player,
      volume: volume ?? this.volume,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoaded: isLoaded ?? this.isLoaded,
      isMuted: isMuted ?? this.isMuted,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MixTrackModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MixTrackModel(id: $id, audio: ${audio.title}, volume: $volume, isPlaying: $isPlaying)';
  }
}
