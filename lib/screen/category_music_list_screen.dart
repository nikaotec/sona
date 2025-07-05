import 'package:flutter/material.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/audio_download_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CategoryMusicListScreen extends StatefulWidget {
  final String categoryName;
  final List<AudioModel> audios;

  const CategoryMusicListScreen({
    super.key,
    required this.categoryName,
    required this.audios,
  });

  @override
  State<CategoryMusicListScreen> createState() => _CategoryMusicListScreenState();
}

class _CategoryMusicListScreenState extends State<CategoryMusicListScreen> {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  int _musicPlayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
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
          debugPrint('Failed to load a banner ad: ${err.message}');
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
          debugPrint('InterstitialAd failed to load: $error');
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
    final paywallProvider = Provider.of<PaywallProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1A1A2E),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _calculateItemCount(paywallProvider.isPremium),
        itemBuilder: (context, index) {
          // Para usuários premium, não mostrar anúncios
          if (paywallProvider.isPremium) {
            final audio = widget.audios[index];
            return _buildAudioTile(audio);
          }

          // Para usuários não premium, intercalar anúncios
          if (index == 0) {
            // Banner no topo
            return _buildBannerAd();
          } else if (index == 3) {
            // Anúncio nativo após 2 músicas
            return _buildNativeAdCard();
          } else if (index == 7) {
            // Segundo banner após mais algumas músicas
            return _buildBannerAd();
          } else {
            // Calcular o índice real do áudio
            int audioIndex = _getAudioIndex(index);
            if (audioIndex < widget.audios.length) {
              final audio = widget.audios[audioIndex];
              return _buildAudioTile(audio);
            }
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  int _calculateItemCount(bool isPremium) {
    if (isPremium) {
      return widget.audios.length;
    }
    // Para não premium: banner inicial + músicas + anúncios intercalados
    return widget.audios.length + 3; // +3 para os anúncios
  }

  int _getAudioIndex(int listIndex) {
    // Mapear o índice da lista para o índice real do áudio
    if (listIndex <= 0) return -1; // Banner inicial
    if (listIndex <= 2) return listIndex - 1; // Primeiras 2 músicas
    if (listIndex == 3) return -1; // Anúncio nativo
    if (listIndex <= 6) return listIndex - 2; // Próximas músicas
    if (listIndex == 7) return -1; // Segundo banner
    return listIndex - 3; // Músicas restantes
  }

  Widget _buildAudioTile(AudioModel audio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
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
          
          // Incrementar contador e mostrar anúncio intersticial a cada 3 músicas
          _musicPlayCount++;
          if (_musicPlayCount % 3 == 0) {
            _showInterstitialAd();
          }
          
          // Exibir anúncio de vídeo recompensado antes de tocar a música
          final adService = Provider.of<AdService>(context, listen: false);
          final paywallProvider = Provider.of<PaywallProvider>(context, listen: false);
          
          await paywallProvider.loadData();
          
          if (!paywallProvider.isPremium) {
            adService.showRewardedAd(
              onUserEarnedRewardCallback: () {
                debugPrint("Usuário ganhou recompensa por assistir anúncio antes de tocar música.");
              },
              onAdDismissed: () {
                debugPrint("Anúncio dispensado, tocando música.");
                Provider.of<AudioProvider>(context, listen: false)
                    .playAudio(context, audio);
                context.go('/player');
              },
              onAdFailedToLoadOrShow: (error) {
                debugPrint("Falha ao carregar/mostrar anúncio: $error. Tocando música diretamente.");
                Provider.of<AudioProvider>(context, listen: false)
                    .playAudio(context, audio);
                context.go('/player');
              },
            );
          } else {
            // Usuário premium, toca diretamente
            Provider.of<AudioProvider>(context, listen: false)
                .playAudio(context, audio);
            context.go('/player');
          }
        },
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
          debugPrint("Usuário ganhou recompensa por assistir anúncio antes do download.");
        },
        onAdDismissed: () {
          debugPrint("Anúncio dispensado, iniciando download.");
          _performDownload(context, audioDownloadService, audio.url, fileName);
        },
        onAdFailedToLoadOrShow: (error) {
          debugPrint("Falha ao carregar/mostrar anúncio para download: $error. Permitindo download mesmo assim.");
          _performDownload(context, audioDownloadService, audio.url, fileName);
        },
      );
    } else {
      debugPrint("Usuário premium, iniciando download direto.");
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
      debugPrint("Erro no download: $e");
    }
  }
}
