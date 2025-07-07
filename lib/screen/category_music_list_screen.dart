import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:sona/widgtes/mini_player_widget.dart';
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

class _CategoryMusicListScreenState extends State<CategoryMusicListScreen>  with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  late VideoAdService _videoAdService;
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  int _musicPlayCount = 0;
  
  late AnimationController _listAnimationController;
  late AnimationController _headerAnimationController;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
    _videoAdService = VideoAdService();
    _videoAdService.loadRewardedInterstitialAd();
    
    // Inicializar controladores de animação
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Iniciar animações
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _listAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _videoAdService.dispose();
    _listAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
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
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _loadInterstitialAd();
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
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0);
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9644FF)],
                  ),
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
            child: AnimatedButton(
              onPressed: () {
                context.go('/paywall');
              },
              child: const Text(
                'Assinar Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.3, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: AnimatedBuilder(
          animation: _headerAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _headerAnimationController.value,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/categories'),
              ),
            );
          },
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
          : AnimatedBuilder(
              animation: _headerAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _headerAnimationController.value)),
                  child: Opacity(
                    opacity: _headerAnimationController.value,
                    child: Text(
                      widget.categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
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
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3, end: 0),
                ),
              ],
              
              // Banner de anúncio no topo para usuários não premium
              if (!paywallProvider.isPremium)
                const BannerAdWidget(),
          
              // Lista de músicas
              Expanded(
                child: AnimatedBuilder(
                  animation: _listAnimationController,
                  builder: (context, child) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _calculateItemCount(paywallProvider.isPremium),
                      itemBuilder: (context, index) {
                        // Para usuários premium, não mostrar anúncios
                        if (paywallProvider.isPremium) {
                          final audio = widget.audios[index];
                          return _buildFixedAnimatedAudioTile(audio, index);
                        }

                        // Para usuários não premium, intercalar anúncios
                        if (index == 3) {
                          return _buildNativeAdCard();
                        } else if (index == 7) {
                          return _buildBannerAd();
                        } else {
                          int audioIndex = _getAudioIndex(index);
                          if (audioIndex < widget.audios.length && audioIndex >= 0) {
                            final audio = widget.audios[audioIndex];
                            return _buildFixedAnimatedAudioTile(audio, audioIndex);
                          }
                        }
                        
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      // Mini Player flutuante
      bottomSheet: const MiniPlayerWidget(
        showOnlyWhenPlaying: true,
        margin: EdgeInsets.all(16),
      ).animate().slideY(begin: 1, end: 0, delay: 1000.ms),
    );
  }

  int _calculateItemCount(bool isPremium) {
    if (isPremium) {
      return widget.audios.length;
    }
    return widget.audios.length + 2;
  }

  int _getAudioIndex(int listIndex) {
    if (listIndex <= 2) return listIndex;
    if (listIndex == 3) return -1;
    if (listIndex <= 6) return listIndex - 1;
    if (listIndex == 7) return -1;
    return listIndex - 2;
  }

  // Versão corrigida sem Hero aninhado
  Widget _buildFixedAnimatedAudioTile(AudioModel audio, int index) {
    final delay = (index * 100).ms;
    
    return Hero(
      tag: 'audio_${audio.id}_$index',
      child: Material(
        color: Colors.transparent,
        child: FixedAnimatedMusicCard(
          audio: audio,
          index: index,
          delay: delay,
          onTap: () => _handleAudioTap(audio, index),
          onDownload: () => _handleDownload(context, audio),
        ),
      ),
    );
  }

  void _handleAudioTap(AudioModel audio, int index) async {
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
      if (_videoAdService.isRewardedInterstitialAdReady) {
        _videoAdService.showVideoAd(
          onUserEarnedRewardCallback: () {},
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
        Provider.of<AudioProvider>(context, listen: false)
            .playAudio(context, audio);
        context.go('/player', extra: {
          'heroTag': 'audio_${audio.id}_$index',
        });
      }
    } else {
      Provider.of<AudioProvider>(context, listen: false)
          .playAudio(context, audio);
      context.go('/player', extra: {
        'heroTag': 'audio_${audio.id}_$index',
      });
    }
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
        onUserEarnedRewardCallback: () {},
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

// Widget corrigido sem Hero aninhado
class FixedAnimatedMusicCard extends StatefulWidget {
  final AudioModel audio;
  final int index;
  final Duration delay;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const FixedAnimatedMusicCard({
    super.key,
    required this.audio,
    required this.index,
    required this.delay,
    required this.onTap,
    required this.onDownload,
  });

  @override
  State<FixedAnimatedMusicCard> createState() => _FixedAnimatedMusicCardState();
}

class _FixedAnimatedMusicCardState extends State<FixedAnimatedMusicCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _colorAnimation = ColorTween(
      begin: const Color(0xFF2A2A3E),
      end: const Color(0xFF6C63FF).withOpacity(0.1),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                // Removido o Hero aninhado - apenas o ícone simples
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
                  widget.audio.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  widget.audio.category,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.audio.isPremium)
                      const Icon(Icons.lock, color: Colors.amber)
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 2000.ms, color: Colors.amber),
                    const SizedBox(width: 8),
                    AnimatedButton(
                      onPressed: widget.onDownload,
                      isIconButton: true,
                      child: const Icon(Icons.download, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).animate(delay: widget.delay).fadeIn().slideX(begin: 0.3, end: 0);
  }
}

// Widget personalizado para botões animados (reutilizado)
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isIconButton;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isIconButton = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isIconButton) {
      return GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                  ),
                ),
                child: widget.child,
              ),
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9644FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}
