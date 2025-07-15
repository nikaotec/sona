import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:sona/provider/subscription_provider.dart';
import 'package:sona/provider/mix_manager_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sona/widgtes/enhanced_mini_player_widget.dart';

class MixListScreen extends StatefulWidget {
  const MixListScreen({super.key});

  @override
  State<MixListScreen> createState() => _MixListScreenState();
}

class _MixListScreenState extends State<MixListScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBannerAd();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Iniciar animações
    _slideController.forward();
    _fadeController.forward();
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

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<EnhancedAudioProvider, SubscriptionProvider, MixManagerProvider>(
      builder: (context, audioProvider, subscriptionProvider, mixManager, child) {
        final activeMixAudios = audioProvider.activeMix.values.toList();
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A5568),
                  Color(0xFF2D3748),
                  Color(0xFF1A1A2E),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header animado
                  _buildAnimatedHeader(screenWidth, activeMixAudios.length, audioProvider),
                  
                  // Banner de anúncio para usuários não premium
                  if (!subscriptionProvider.hasActiveSubscription)
                    _buildBannerAd()
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: -0.3, end: 0),
                  
                  // Conteúdo principal
                  Expanded(
                    child: activeMixAudios.isEmpty
                        ? _buildEmptyState(screenWidth)
                        : _buildMixList(audioProvider, activeMixAudios, screenWidth),
                  ),
                ],
              ),
            ),
          ),
          // Mini Player flutuante
          bottomSheet: const EnhancedMiniPlayerWidget(
            showOnlyWhenPlaying: true,
            margin: EdgeInsets.all(16),
          ),
          // FAB para salvar mix
          floatingActionButton: activeMixAudios.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _showSaveMixDialog(context, activeMixAudios, mixManager),
                  backgroundColor: const Color(0xFF6C63FF),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Salvar Mix',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms).scale()
              : null,
        );
      },
    );
  }

  Widget _buildBannerAd() {
    if (_isBannerAdReady && _bannerAd != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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

  Widget _buildAnimatedHeader(double screenWidth, int mixCount, EnhancedAudioProvider audioProvider) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              Row(
                children: [
                  // Botão voltar
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Título e contador
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mix Ativo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        Text(
                          '$mixCount ${mixCount == 1 ? 'música' : 'músicas'} tocando',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.035,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botão reproduzir/pausar tudo
                  if (mixCount > 0)
                    GestureDetector(
                      onTap: () {
                        if (audioProvider.isPlaying) {
                          audioProvider.pauseMix();
                        } else {
                          audioProvider.resumeMix();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6C63FF),
                              Color(0xFF9644FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Botões de ação
              if (mixCount > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Botão limpar tudo
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _showClearConfirmationDialog(audioProvider);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.clear_all,
                                color: Colors.red.withOpacity(0.8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Limpar Tudo',
                                style: TextStyle(
                                  color: Colors.red.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: screenWidth * 0.3,
                height: screenWidth * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.queue_music,
                  size: screenWidth * 0.15,
                  color: Colors.white.withOpacity(0.5),
                ),
              ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 24),
              
              Text(
                'Nenhum mix ativo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 12),
              
              Text(
                'Adicione músicas ao mix na tela do player para criar sua experiência sonora personalizada',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: screenWidth * 0.035,
                  height: 1.4,
                  fontFamily: 'Open Sans',
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 32),
              
              GestureDetector(
                onTap: () => context.go('/categories'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF9644FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Explorar Músicas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).scale(curve: Curves.elasticOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMixList(EnhancedAudioProvider audioProvider, List<AudioModel> mixList, double screenWidth) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          itemCount: mixList.length,
          itemBuilder: (context, index) {
            final audio = mixList[index];
            final isCurrentlyPlaying = audioProvider.currentAudio?.id == audio.id;
            final volume = audioProvider.getMixAudioVolume(audio.id);
            
            return _buildMixItem(
              audio,
              index,
              screenWidth,
              audioProvider,
              isCurrentlyPlaying,
              volume,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMixItem(
    AudioModel audio,
    int index,
    double screenWidth,
    EnhancedAudioProvider audioProvider,
    bool isCurrentlyPlaying,
    double volume,
  ) {
    return Container(
      key: ValueKey(audio.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentlyPlaying 
            ? const Color(0xFF6C63FF).withOpacity(0.1)
            : const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentlyPlaying
            ? Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.5),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            audioProvider.playMainAudio(context, audio);
            context.go('/player');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Ícone da categoria
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(audio.category).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(audio.category),
                        color: _getCategoryColor(audio.category),
                        size: 24,
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
                                  audio.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: isCurrentlyPlaying 
                                        ? FontWeight.bold 
                                        : FontWeight.w600,
                                    fontFamily: 'Montserrat',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrentlyPlaying) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Tocando',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ).animate().scale(curve: Curves.elasticOut),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                audio.category,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white54,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(audio.duration),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                              if (audio.isPremium) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Botão remover do mix
                    GestureDetector(
                      onTap: () {
                        _showRemoveConfirmationDialog(audioProvider, audio);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Controle de volume
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
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.3, end: 0);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'binaural':
        return const Color(0xFF6C63FF);
      case 'natureza':
      case 'nature sounds':
        return const Color(0xFF4CAF50);
      case 'white noise':
        return const Color(0xFF9C27B0);
      case 'meditação':
      case 'meditation':
        return const Color(0xFFFF9800);
      case 'sleep':
        return const Color(0xFF3F51B5);
      case 'instrumental':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'binaural':
        return Icons.graphic_eq;
      case 'natureza':
      case 'nature sounds':
        return Icons.nature_outlined;
      case 'white noise':
        return Icons.blur_on;
      case 'meditação':
      case 'meditation':
        return Icons.self_improvement;
      case 'sleep':
        return Icons.nightlight_round;
      case 'instrumental':
        return Icons.music_note;
      default:
        return Icons.music_note;
    }
  }

  void _showRemoveConfirmationDialog(EnhancedAudioProvider audioProvider, AudioModel audio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Remover do Mix',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        content: Text(
          'Deseja remover "${audio.title}" do mix ativo?',
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Open Sans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              audioProvider.removeFromMix(audio.id);
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${audio.title} removido do mix'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text(
              'Remover',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmationDialog(EnhancedAudioProvider audioProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Limpar Mix',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        content: const Text(
          'Deseja remover todas as músicas do mix ativo? Esta ação não pode ser desfeita.',
          style: TextStyle(
            color: Colors.white70,
            fontFamily: 'Open Sans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              audioProvider.clearMix();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mix limpo com sucesso'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Limpar Tudo',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveMixDialog(BuildContext context, List<AudioModel> audios, MixManagerProvider mixManager) {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Salvar Mix',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dê um nome para seu mix com ${audios.length} música${audios.length > 1 ? 's' : ''}:',
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Open Sans',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nome do mix...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                try {
                  await mixManager.createMix(
                    name: name,
                    audios: audios,
                  );
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mix "$name" salvo com sucesso!'),
                      backgroundColor: const Color(0xFF6C63FF),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao salvar mix: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Salvar',
              style: TextStyle(color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }
}
