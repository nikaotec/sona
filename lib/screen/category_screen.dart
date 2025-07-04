import 'package:flutter/material.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:provider/provider.dart';
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
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', //  BannerAd., // Use test ad unit ID for development
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
        'icon': Icons.headphones,
      },
      {
        'title': 'Nature Sounds',
        'subtitle': 'Rain, Ocean, Wind, and more',
        'icon': Icons.cloud,
      },
      {
        'title': 'White / Pink / Brown Noise',
        'subtitle': 'Ambient noise generators',
        'icon': Icons.grain,
      },
      {
        'title': 'Guided Meditations',
        'subtitle': 'Mindfulness and relaxation',
        'icon': Icons.self_improvement,
      },
      {
        'title': 'Sleep',
        'subtitle': 'Mixes for deep sleep',
        'icon': Icons.bedtime,
      },
      {
        'title': 'Ready Made Mixes',
        'subtitle': 'Curated soundscapes',
        'icon': Icons.music_note,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindWave'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.go('/profile');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categories',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0, // Adjust as needed
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () {
                      // TODO: Implement navigation to specific category content
                      print('Category tapped: ${category['title']}');
                    },
                    child: Card(
                      color: Colors.grey[850],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category['icon'], size: 48, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            category['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            category['subtitle'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Popular',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // TODO: Implement Popular section based on images
            // For now, a placeholder
            Container(
              height: 150,
              color: Colors.grey[800],
              child: const Center(child: Text('Popular Section Placeholder')),
            ),
            const SizedBox(height: 16),
            // TODO: Implement bottom player based on images
            // For now, a placeholder
            Container(
              height: 60,
              color: Colors.grey[900],
              child: const Center(child: Text('Player Placeholder')),
            ),
            if (_isBannerAdLoaded)
              SizedBox(
                width: _bannerAd.size.width.toDouble(),
                height: _bannerAd.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd),
              ),
          ],
        ),
      ),
    );
  }
}


