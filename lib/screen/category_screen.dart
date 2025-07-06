import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/subscription_provider.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados das categorias baseados na imagem de referência
    final categories = [
      {
        'title': 'Binaural Beats',
        'subtitle': 'Brainwave entrainment',
        'icon': Icons.graphic_eq,
        'audios': [
          AudioModel(
            id: '1',
            title: 'Binaural Beats Delta',
            url: 'assets/music/bineural/binaural-beats_delta_440_440-5hz-48565.mp3',
            category: 'Binaural Beats',
            duration: const Duration(minutes: 5),
            isPremium: false,
          ),
          AudioModel(
            id: '2',
            title: 'Alpha Waves Focus',
            url: 'https://example.com/alpha.mp3',
            category: 'Binaural Beats',
            duration: const Duration(minutes: 8),
            isPremium: true,
          ),
        ],
      },
      {
        'title': 'Nature Sounds',
        'subtitle': 'Rain, Ocean, Wind, and more',
        'icon': Icons.cloud,
        'audios': [
          AudioModel(
            id: '3',
            title: 'Tranquil Pond',
            url: 'https://example.com/audio1.mp3',
            category: 'Nature Sounds',
            duration: const Duration(minutes: 10),
            isPremium: false,
          ),
          AudioModel(
            id: '4',
            title: 'Ocean Waves',
            url: 'https://example.com/ocean.mp3',
            category: 'Nature Sounds',
            duration: const Duration(minutes: 15),
            isPremium: true,
          ),
        ],
      },
      {
        'title': 'White Noise / Pink / Brown',
        'subtitle': 'Ambient noise generators',
        'icon': Icons.blur_on,
        'audios': [
          AudioModel(
            id: '5',
            title: 'White Noise',
            url: 'https://example.com/white_noise.mp3',
            category: 'White Noise',
            duration: const Duration(minutes: 30),
            isPremium: false,
          ),
          AudioModel(
            id: '6',
            title: 'Pink Noise',
            url: 'https://example.com/pink_noise.mp3',
            category: 'Pink Noise',
            duration: const Duration(minutes: 30),
            isPremium: true,
          ),
        ],
      },
      {
        'title': 'Guided Meditations',
        'subtitle': 'Mindfulness and relaxation',
        'icon': Icons.self_improvement,
        'audios': [
          AudioModel(
            id: '7',
            title: 'Body Scan',
            url: 'https://example.com/audio2.mp3',
            category: 'Guided Meditations',
            duration: const Duration(minutes: 10),
            isPremium: true,
          ),
          AudioModel(
            id: '8',
            title: 'Breathing Exercise',
            url: 'https://example.com/breathing.mp3',
            category: 'Guided Meditations',
            duration: const Duration(minutes: 5),
            isPremium: false,
          ),
        ],
      },
      {
        'title': 'Sleep',
        'subtitle': 'Mixes for deep sleep',
        'icon': Icons.nightlight_round,
        'audios': [
          AudioModel(
            id: '9',
            title: 'Deep Sleep Mix',
            url: 'https://example.com/sleep.mp3',
            category: 'Sleep',
            duration: const Duration(hours: 1),
            isPremium: true,
          ),
          AudioModel(
            id: '10',
            title: 'Lullaby',
            url: 'https://example.com/lullaby.mp3',
            category: 'Sleep',
            duration: const Duration(minutes: 20),
            isPremium: false,
          ),
        ],
      },
    ];

    // Dados dos populares baseados na imagem
    final popularItems = [
      {
        'title': 'Tranquil Pond',
        'subtitle': 'Nature Mix',
        'color': const Color(0xFF4A6741),
        'audio': AudioModel(
          id: '11',
          title: 'Tranquil Pond',
          url: 'https://example.com/tranquil_pond.mp3',
          category: 'Nature Mix',
          duration: const Duration(minutes: 12),
          isPremium: false,
        ),
      },
      {
        'title': 'Serenity',
        'subtitle': 'Sleep Mix',
        'color': const Color(0xFF4A4A8A),
        'audio': AudioModel(
          id: '12',
          title: 'Serenity',
          url: 'https://example.com/serenity.mp3',
          category: 'Sleep Mix',
          duration: const Duration(minutes: 25),
          isPremium: true,
        ),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'MindWave',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              context.go('/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Consumer<SubscriptionProvider>(
          builder: (context, subscriptionProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Banner de Assinatura (visível apenas para não-premium)
                if (!subscriptionProvider.hasActiveSubscription) ...[
                  GestureDetector(
                    onTap: () {
                      context.go('/paywall');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B73FF), Color(0xFF9644FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B73FF).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Desbloqueie o Premium!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Acesso ilimitado, sem anúncios e downloads offline. Toque para assinar!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 12),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Lista de categorias com Hero animation
                ...categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;

                  return Hero(
                    tag: 'category_${category['title']}_$index',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A4E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              category['icon'] as IconData,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            category['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            category['subtitle'] as String,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            context.go('/category-music-list', extra: {
                              'categoryName': category['title'] as String,
                              'audios': category['audios'] as List<AudioModel>,
                              'heroTag': 'category_${category['title']}_$index',
                            });
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 32),

                // Seção Popular
                const Text(
                  'Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Grid de itens populares
                Row(
                  children: popularItems.map((item) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      height: 160,
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['subtitle'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 24),

                // Player mini na parte inferior
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A4E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Dreamy Ambience',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: () {
                          // Lógica de play
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () {
                          // Lógica de próxima música
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


