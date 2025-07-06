import 'package:flutter/material.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/provider/subscription_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/video_ad_service.dart';
import 'package:sona/service/audio_download_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sona/components/banner_ad_widget.dart';
import 'package:sona/widgtes/subscription_banner.dart';

class CategoryMusicListScreen extends StatefulWidget {
  final String categoryName;
  final List<AudioModel> audios;
  final String? heroTag;

  const CategoryMusicListScreen({
    super.key,
    required this.categoryName,
    required this.audios,
    this.heroTag,
  });

  @override
  State<CategoryMusicListScreen> createState() => _CategoryMusicListScreenState();
}

class _CategoryMusicListScreenState extends State<CategoryMusicListScreen> {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  late VideoAdService _videoAdService;
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  int _musicPlayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
    _videoAdService = VideoAdService();
    _videoAdService.loadRewardedInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _loadInterstitialAd(); // Carrega um novo anúncio
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _loadInterstitialAd(); // Carrega um novo anúncio
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _videoAdService.dispose();
    super.dispose();
  }

  Widget _buildBannerAd() {
    if (_isBannerAdReady && _bannerAd != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.ads_click, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Anúncio',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildNativeAdCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.ads_click, color: Colors.grey[400], size: 16),
              const SizedBox(width: 6),
              Text(
                'Anúncio Patrocinado',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A8A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.headphones, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium Music Experience',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Desfrute de música sem anúncios e downloads ilimitados',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navegar para paywall ou ação do anúncio
                context.go('/paywall');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Assinar Premium'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/categories'),
        ),
        title: widget.heroTag != null 
          ? Hero(
              tag: widget.heroTag!,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  widget.categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : Text(
              widget.categoryName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
        centerTitle: true,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          final paywallProvider = Provider.of<PaywallProvider>(context);
          
          return Column(
            children: [
              // Banner de assinatura para usuários não premium
              if (!subscriptionProvider.hasActiveSubscription) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CompactSubscriptionBanner(
                    onTap: () => context.go('/paywall'),
                  ),
                ),
              ],
              
              // Banner de anúncio no topo para usuários não premium
              if (!paywallProvider.isPremium)
                const BannerAdWidget(),
          
          // Lista de músicas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _calculateItemCount(paywallProvider.isPremium),
              itemBuilder: (context, index) {
                // Para usuários premium, não mostrar anúncios
                if (paywallProvider.isPremium) {
                  final audio = widget.audios[index];
                  return _buildAudioTile(audio, index);
                }

                // Para usuários não premium, intercalar anúncios
                if (index == 3) {
                  // Anúncio nativo após 3 músicas
                  return _buildNativeAdCard();
                } else if (index == 7) {
                  // Segundo banner após mais algumas músicas
                  return _buildBannerAd();
                } else {
                  // Calcular o índice real do áudio
                  int audioIndex = _getAudioIndex(index);
                  if (audioIndex < widget.audios.length && audioIndex >= 0) {
                    final audio = widget.audios[audioIndex];
                    return _buildAudioTile(audio, audioIndex);
                  }
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      );
        },
      ),
    );
  }

  int _calculateItemCount(bool isPremium) {
    if (isPremium) {
      return widget.audios.length;
    }
    // Para não premium: músicas + anúncios intercalados
    return widget.audios.length + 2; // +2 para os anúncios
  }

  int _getAudioIndex(int listIndex) {
    // Mapear o índice da lista para o índice real do áudio
    if (listIndex <= 2) return listIndex; // Primeiras 3 músicas
    if (listIndex == 3) return -1; // Anúncio nativo
    if (listIndex <= 6) return listIndex - 1; // Próximas músicas
    if (listIndex == 7) return -1; // Segundo banner
    return listIndex - 2; // Músicas restantes
  }

  Widget _buildAudioTile(AudioModel audio, int index) {
    return Hero(
      tag: 'audio_${audio.id}_$index',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B73FF), Color(0xFF9644FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              audio.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              audio.category,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (audio.isPremium)
                  const Icon(Icons.lock, color: Colors.amber),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    _handleDownload(context, audio);
                  },
                ),
              ],
            ),
            onTap: () async {
              if (audio.isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${audio.title} é um áudio premium. Assine para ouvir!'),
                    backgroundColor: Colors.amber,
                  ),
                );
                return;
              }
              
              final paywallProvider = Provider.of<PaywallProvider>(context, listen: false);
              await paywallProvider.loadData();
              
              if (!paywallProvider.isPremium) {
                // Mostrar anúncio em vídeo para usuários não assinantes
                if (_videoAdService.isRewardedInterstitialAdReady) {
                  _videoAdService.showVideoAd(
                    onUserEarnedRewardCallback: () {
                    },
                    onAdDismissed: () {
                      Provider.of<AudioProvider>(context, listen: false)
                          .playAudio(context, audio);
                      context.go('/player', extra: {
                        'heroTag': 'audio_${audio.id}_$index',
                      });
                    },
                    onAdFailedToLoadOrShow: (error) {
                      Provider.of<AudioProvider>(context, listen: false)
                          .playAudio(context, audio);
                      context.go('/player', extra: {
                        'heroTag': 'audio_${audio.id}_$index',
                      });
                    },
                  );
                } else {
                  // Se o anúncio não está pronto, toca a música diretamente
                  Provider.of<AudioProvider>(context, listen: false)
                      .playAudio(context, audio);
                  context.go('/player', extra: {
                    'heroTag': 'audio_${audio.id}_$index',
                  });
                }
              } else {
                // Usuário premium, navega diretamente
                Provider.of<AudioProvider>(context, listen: false)
                    .playAudio(context, audio);
                context.go('/player', extra: {
                  'heroTag': 'audio_${audio.id}_$index',
                });
              }
            },
          ),
        ),
      ),
    );
  }

  void _handleDownload(BuildContext context, AudioModel audio) async {
    final paywallProvider = Provider.of<PaywallProvider>(context, listen: false);
    final adService = Provider.of<AdService>(context, listen: false);
    final audioDownloadService = Provider.of<AudioDownloadService>(context, listen: false);

    await paywallProvider.loadData();

    final String fileName = "${audio.title.replaceAll(' ', '_')}.mp3";

    bool alreadyDownloaded = await audioDownloadService.isDownloaded(fileName);
    if (alreadyDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${audio.title} já foi baixado.')),
      );
      return;
    }

    if (audio.isPremium && !paywallProvider.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assine o plano premium para baixar ${audio.title}.')),
      );
      return;
    }

    if (!paywallProvider.isPremium) {
      adService.showRewardedAd(
        onUserEarnedRewardCallback: () {
        },
        onAdDismissed: () {
          _performDownload(context, audioDownloadService, audio.url, fileName);
        },
        onAdFailedToLoadOrShow: (error) {
          _performDownload(context, audioDownloadService, audio.url, fileName);
        },
      );
    } else {
      _performDownload(context, audioDownloadService, audio.url, fileName);
    }
  }

  void _performDownload(BuildContext context, AudioDownloadService downloadService, String url, String fileName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Baixando ${fileName}...')),
      );
      await downloadService.downloadAudio(url, fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${fileName} baixado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao baixar ${fileName}: $e')),
      );
    }
  }
}

