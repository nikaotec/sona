import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBannerAd();
  }

  _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('BannerAd failed to load: $error');
        },
      ),
    );
    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'title': 'Binaural Beats',
        'subtitle': 'Brainwave entrainment',
        'icon': Icons.show_chart,
        'color': const Color(0xFF2A2A3A),
      },
      {
        'title': 'Nature Sounds',
        'subtitle': 'Rain, Ocean, Wind, and more',
        'icon': Icons.cloud_outlined,
        'color': const Color(0xFF2A2A3A),
      },
      {
        'title': 'White Noise / Pink / Brown',
        'subtitle': 'Ambient noise generators',
        'icon': Icons.grain,
        'color': const Color(0xFF2A2A3A),
      },
      {
        'title': 'Guided Meditations',
        'subtitle': 'Mindfulness and relaxation',
        'icon': Icons.self_improvement,
        'color': const Color(0xFF2A2A3A),
      },
      {
        'title': 'Sleep',
        'subtitle': 'Mixes for deep sleep',
        'icon': Icons.bedtime,
        'color': const Color(0xFF2A2A3A),
      },
    ];

    final List<Map<String, dynamic>> popularItems = [
      {
        'title': 'Tranquil Pond',
        'subtitle': 'Nature Mix',
        'image': 'assets/images/tranquil_pond.jpg',
        'color': const Color(0xFF4A7C7E),
      },
      {
        'title': 'Serenity',
        'subtitle': 'Sleep Mix',
        'image': 'assets/images/serenity.jpg',
        'color': const Color(0xFF5A4FCF),
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF2A2A3A),
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  context.go('/profile');
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Categories List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        print('Category tapped: ${category['title']}');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: category['color'],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3A4A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                category['icon'],
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    category['subtitle'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Popular Section
              const Text(
                'Popular',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              // Popular Items Grid
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        print('Tranquil Pond tapped');
                      },
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: popularItems[0]['color'],
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              popularItems[0]['color'],
                              (popularItems[0]['color'] as Color).withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    popularItems[0]['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    popularItems[0]['subtitle'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        print('Serenity tapped');
                      },
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: popularItems[1]['color'],
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              popularItems[1]['color'],
                              (popularItems[1]['color'] as Color).withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    popularItems[1]['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    popularItems[1]['subtitle'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Bottom Player
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A4A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Dreamy Ambience',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        print('Play button tapped');
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        print('Next button tapped');
                      },
                      icon: const Icon(
                        Icons.skip_next,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Banner Ad
              if (_isBannerAdLoaded)
                Center(
                  child: SizedBox(
                    width: _bannerAd.size.width.toDouble(),
                    height: _bannerAd.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
