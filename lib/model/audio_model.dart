class AudioModel {
  final String id;
  final String title;
  final String url;
  final String category;
  final Duration duration;
  final bool isPremium;

  AudioModel({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    required this.duration,
    this.isPremium = false,
  });

  factory AudioModel.fromMap(Map<String, dynamic> map) {
    return AudioModel(
      id: map['id'],
      title: map['title'],
      url: map['url'],
      category: map['category'],
      duration: Duration(seconds: map['duration']),
      isPremium: map['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'title': title,
    'url': url,
    'category': category,
    'duration': duration.inSeconds,
    'isPremium': isPremium,
  };
}

}
