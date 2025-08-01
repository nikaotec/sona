import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/provider/subscription_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/video_ad_service.dart';
import 'package:sona/service/audio_download_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sona/widgtes/enhanced_mini_player_widget.dart';

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

class _CategoryMusicListScreenState extends State<CategoryMusicListScreen>
    with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  late VideoAdService _videoAdService;
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  
  late AnimationController _listAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _fabAnimationController;

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
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Iniciar animações
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _listAnimationController.forward();
        _fabAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _videoAdService.dispose();
    _listAnimationController.dispose();
    _headerAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
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
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
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
          // Handle error
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: _buildAppBar(),
      body: Consumer2<SubscriptionProvider, EnhancedAudioProvider>(
        builder: (context, subscriptionProvider, audioProvider, child) {
          final paywallProvider = Provider.of<PaywallProvider>(context);
          
          return Column(
            children: [
              // Banner de assinatura para usuários não premium
              if (!subscriptionProvider.hasActiveSubscription) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPremiumBanner()
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: -0.3, end: 0),
                ),
              ],
              
              // Estatísticas do mix (se ativo)
              if (audioProvider.hasMixActive)
                _buildMixStats(audioProvider),
              
              // Lista de músicas
              Expanded(
                child: _buildMusicList(paywallProvider.isPremium, audioProvider),
              ),
            ],
          );
        },
      ),
      // Mini Player aprimorado
      bottomSheet: const EnhancedMiniPlayerWidget(
        showOnlyWhenPlaying: true,
        margin: EdgeInsets.all(16),
      ).animate().slideY(begin: 1, end: 0, delay: 1000.ms),
      
      // FAB para controles de mix
      floatingActionButton: Consumer<EnhancedAudioProvider>(
        builder: (context, audioProvider, child) {
          if (!audioProvider.hasMixActive) return const SizedBox.shrink();
          
          return AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabAnimationController.value,
                child: FloatingActionButton.extended(
                  onPressed: () => _showMixBottomSheet(audioProvider),
                  backgroundColor: const Color(0xFF6C63FF),
                  icon: const Icon(Icons.queue_music, color: Colors.white),
                  label: Text(
                    'Mix (${audioProvider.mixCount})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      leading: AnimatedBuilder(
        animation: _headerAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _headerAnimationController.value,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              );
            },
          ),
      centerTitle: true,
      actions: [
        Consumer<EnhancedAudioProvider>(
          builder: (context, audioProvider, child) {
            return AnimatedBuilder(
              animation: _headerAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _headerAnimationController.value,
                  child: IconButton(
                    icon: Badge(
                      isLabelVisible: audioProvider.hasMixActive,
                      label: Text('${audioProvider.mixCount}'),
                      child: const Icon(Icons.queue_music, color: Colors.white),
                    ),
                    onPressed: () => _showMixBottomSheet(audioProvider),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Desbloqueie o Premium!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mix ilimitado, sem anúncios e downloads offline',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildMixStats(EnhancedAudioProvider audioProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.queue_music,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mix Ativo',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Text(
                      '${audioProvider.mixCount} áudio${audioProvider.mixCount > 1 ? 's' : ''} tocando simultaneamente',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showMixBottomSheet(audioProvider),
            child: const Text(
              'Gerenciar',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildMusicList(bool isPremium, EnhancedAudioProvider audioProvider) {
    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _calculateItemCount(isPremium),
          itemBuilder: (context, index) {
            // Para usuários premium, não mostrar anúncios
            if (isPremium) {
              final audio = widget.audios[index];
              return _buildEnhancedAudioTile(audio, index, audioProvider);
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
                return _buildEnhancedAudioTile(audio, audioIndex, audioProvider);
              }
            }
            
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildEnhancedAudioTile(AudioModel audio, int index, EnhancedAudioProvider audioProvider) {
    final delay = (index * 100).ms;
    final isInMix = audioProvider.isInMix(audio.id);
    final isCurrentAudio = audioProvider.currentAudio?.id == audio.id;
    
    return Hero(
      tag: 'audio_${audio.id}_$index',
      child: Material(
        color: Colors.transparent,
        child: EnhancedMusicCard(
          audio: audio,
          index: index,
          delay: delay,
          isInMix: isInMix,
          isCurrentAudio: isCurrentAudio,
          mixVolume: audioProvider.getMixAudioVolume(audio.id),
          onTap: () => _handleAudioTap(audio, index, audioProvider),
          onMixToggle: () => _handleMixToggle(audio, audioProvider),
          onDownload: () => _handleDownload(context, audio),
        ),
      ),
    );
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
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Desfrute de música sem anúncios e downloads ilimitados',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontFamily: 'Open Sans',
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
              onPressed: () => context.go('/paywall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Assinar Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.3, end: 0);
  }

  void _handleAudioTap(AudioModel audio, int index, EnhancedAudioProvider audioProvider) async {
    try {
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
              _playAudioAndNavigate(audioProvider, audio, index);
            },
            onAdFailedToLoadOrShow: (error) {
              _playAudioAndNavigate(audioProvider, audio, index);
            },
          );
        } else {
          _playAudioAndNavigate(audioProvider, audio, index);
        }
      } else {
        _playAudioAndNavigate(audioProvider, audio, index);
      }
    } catch (e) {
      debugPrint("Erro ao tocar áudio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reproduzir ${audio.title}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _playAudioAndNavigate(EnhancedAudioProvider audioProvider, AudioModel audio, int index) async {
    try {
      // Certifica-se de que o BuildContext é válido antes de usá-lo
      if (!mounted) return; 

      await audioProvider.playMainAudio(context, audio);
      
      // Navega para a tela do player SOMENTE APÓS a reprodução ter sido iniciada com sucesso
      if (mounted) {
        context.go('/player', extra: {
          'heroTag': 'audio_${audio.id}_$index',
        });
      }
    } catch (e) {
      debugPrint("Erro ao reproduzir áudio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reproduzir ${audio.title}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMixToggle(AudioModel audio, EnhancedAudioProvider audioProvider) async {
    try {
      if (audioProvider.isInMix(audio.id)) {
        audioProvider.removeFromMix(audio.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${audio.title} removido do mix'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Adiciona um pequeno delay para evitar duplo clique
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (!audioProvider.isInMix(audio.id)) {
          await audioProvider.addToMix(audio);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${audio.title} adicionado ao mix'),
                backgroundColor: const Color(0xFF6C63FF),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao alterar mix: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar mix: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  void _showMixBottomSheet(EnhancedAudioProvider audioProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Consumer<EnhancedAudioProvider>(
                builder: (context, provider, child) {
                  return provider.hasMixActive
                      ? _buildMixControlsContent(provider)
                      : _buildEmptyMixContent();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMixControlsContent(EnhancedAudioProvider audioProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.queue_music,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Controles de Mix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      '${audioProvider.mixCount} áudio${audioProvider.mixCount > 1 ? 's' : ''} ativo${audioProvider.mixCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: audioProvider.activeMix.length,
            itemBuilder: (context, index) {
              final entry = audioProvider.activeMix.entries.elementAt(index);
              final playerId = entry.key;
              final audio = entry.value;
              final volume = audioProvider.mixVolumes[playerId] ?? 1.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Color(0xFF6C63FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                audio.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                audio.category,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            audioProvider.removeFromMix(audio.id);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.volume_up,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF6C63FF),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFF6C63FF),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              trackHeight: 4,
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              value: volume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) {
                                audioProvider.setMixAudioVolume(audio.id, value);
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${(volume * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => audioProvider.pauseMix(),
                  icon: const Icon(Icons.pause, size: 18),
                  label: const Text('Pausar Mix'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => audioProvider.resumeMix(),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Retomar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showClearMixDialog(audioProvider),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Limpar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMixContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.queue_music,
              color: Color(0xFF6C63FF),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum Mix Ativo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão "Adicionar ao Mix" em qualquer música\npara começar a criar seu mix personalizado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'Open Sans',
            ),
          ),
        ],
      ),
    );
  }

  void _showClearMixDialog(EnhancedAudioProvider audioProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Limpar Mix',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
        ),
        content: const Text(
          'Tem certeza que deseja remover todos os áudios do mix?',
          style: TextStyle(
            color: Colors.white70,
            fontFamily: 'Open Sans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              audioProvider.clearMix();
              Navigator.pop(context);
              Navigator.pop(context); // Fechar bottom sheet também
            },
            child: const Text(
              'Limpar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
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
}

// Widget aprimorado para cards de música
class EnhancedMusicCard extends StatefulWidget {
  final AudioModel audio;
  final int index;
  final Duration delay;
  final bool isInMix;
  final bool isCurrentAudio;
  final double mixVolume;
  final VoidCallback onTap;
  final VoidCallback onMixToggle;
  final VoidCallback onDownload;

  const EnhancedMusicCard({
    super.key,
    required this.audio,
    required this.index,
    required this.delay,
    required this.isInMix,
    required this.isCurrentAudio,
    required this.mixVolume,
    required this.onTap,
    required this.onMixToggle,
    required this.onDownload,
  });

  @override
  State<EnhancedMusicCard> createState() => _EnhancedMusicCardState();
}

class _EnhancedMusicCardState extends State<EnhancedMusicCard>
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
                color: widget.isCurrentAudio 
                    ? const Color(0xFF6C63FF).withOpacity(0.2)
                    : (widget.isInMix 
                        ? const Color(0xFF6C63FF).withOpacity(0.1)
                        : _colorAnimation.value),
                borderRadius: BorderRadius.circular(16),
                border: widget.isCurrentAudio || widget.isInMix
                    ? Border.all(
                        color: const Color(0xFF6C63FF).withOpacity(0.5),
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Artwork/Ícone
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isCurrentAudio
                              ? [const Color(0xFF6C63FF), const Color(0xFF9644FF)]
                              : [const Color(0xFF6B73FF), const Color(0xFF9644FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          if (widget.isCurrentAudio)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Informações da música
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.audio.title,
                                  style: TextStyle(
                                    color: widget.isCurrentAudio 
                                        ? const Color(0xFF6C63FF)
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Montserrat',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.audio.isPremium)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                widget.audio.category,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(widget.audio.duration),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                            ],
                          ),
                          if (widget.isInMix) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.queue_music,
                                  color: Color(0xFF6C63FF),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'No Mix (${(widget.mixVolume * 100).round()}%)',
                                  style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Open Sans',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Botões de ação
                    Column(
                      children: [

                        // Botão de Download
                        GestureDetector(
                          onTap: widget.onDownload,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A3E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF6C63FF).withOpacity(0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.download_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}

