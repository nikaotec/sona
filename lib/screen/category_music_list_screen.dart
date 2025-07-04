import 'package:flutter/material.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/audio_download_service.dart';
import 'package:sona/service/music_repository_service.dart';

class CategoryMusicListScreen extends StatefulWidget {
  final String categoryName;
  final String categoryIcon;
  final String categoryDescription;

  const CategoryMusicListScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryDescription,
  });

  @override
  State<CategoryMusicListScreen> createState() => _CategoryMusicListScreenState();
}

class _CategoryMusicListScreenState extends State<CategoryMusicListScreen> {
  List<AudioModel> categoryAudios = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryAudios();
  }

  void _loadCategoryAudios() async {
    try {
      final musicService = Provider.of<MusicRepositoryService>(context, listen: false);
      
      // Configurar repositório remoto se necessário
      // musicService.setRemoteRepository('https://your-remote-repo.com');
      
      List<AudioModel> musics = await musicService.getMusicsByCategory(widget.categoryName);
      
      setState(() {
        categoryAudios = musics;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar músicas: $e');
      setState(() {
        categoryAudios = _getFallbackMusicsByCategory(widget.categoryName);
        isLoading = false;
      });
    }
  }

  // Método de fallback caso o serviço falhe
  List<AudioModel> _getFallbackMusicsByCategory(String category) {
    // Dados de exemplo - substitua pela lógica real de carregamento
    switch (category) {
      case 'Binaural Beats':
        return [
          AudioModel(
            id: 'bb1',
            title: 'Delta Waves 4Hz',
            url: 'assets/music/bineural/binaural-beats_delta_440_440-5hz-48565.mp3',
            category: 'Binaural Beats',
            duration: const Duration(minutes: 30),
            isPremium: false,
          ),
          AudioModel(
            id: 'bb2',
            title: 'Alpha Waves 10Hz',
            url: 'https://example.com/alpha-waves.mp3',
            category: 'Binaural Beats',
            duration: const Duration(minutes: 25),
            isPremium: true,
          ),
          AudioModel(
            id: 'bb3',
            title: 'Theta Waves 6Hz',
            url: 'https://example.com/theta-waves.mp3',
            category: 'Binaural Beats',
            duration: const Duration(minutes: 35),
            isPremium: false,
          ),
          AudioModel(
            id: 'bb4',
            title: 'Beta Waves 15Hz',
            url: 'https://example.com/beta-waves.mp3',
            category: 'Binaural Beats',
            duration: const Duration(minutes: 20),
            isPremium: true,
          ),
        ];
      case 'Nature Sounds':
        return [
          AudioModel(
            id: 'ns1',
            title: 'Ocean Waves',
            url: 'https://example.com/ocean-waves.mp3',
            category: 'Nature Sounds',
            duration: const Duration(minutes: 45),
            isPremium: false,
          ),
          AudioModel(
            id: 'ns2',
            title: 'Forest Rain',
            url: 'https://example.com/forest-rain.mp3',
            category: 'Nature Sounds',
            duration: const Duration(minutes: 60),
            isPremium: true,
          ),
          AudioModel(
            id: 'ns3',
            title: 'Mountain Stream',
            url: 'https://example.com/mountain-stream.mp3',
            category: 'Nature Sounds',
            duration: const Duration(minutes: 40),
            isPremium: false,
          ),
        ];
      case 'Guided Meditations':
        return [
          AudioModel(
            id: 'gm1',
            title: 'Body Scan Meditation',
            url: 'https://example.com/body-scan.mp3',
            category: 'Guided Meditations',
            duration: const Duration(minutes: 15),
            isPremium: true,
          ),
          AudioModel(
            id: 'gm2',
            title: 'Breathing Exercise',
            url: 'https://example.com/breathing.mp3',
            category: 'Guided Meditations',
            duration: const Duration(minutes: 10),
            isPremium: false,
          ),
        ];
      case 'Sleep':
        return [
          AudioModel(
            id: 'sl1',
            title: 'Deep Sleep Mix',
            url: 'https://example.com/deep-sleep.mp3',
            category: 'Sleep',
            duration: const Duration(hours: 8),
            isPremium: true,
          ),
          AudioModel(
            id: 'sl2',
            title: 'Bedtime Stories',
            url: 'https://example.com/bedtime-stories.mp3',
            category: 'Sleep',
            duration: const Duration(minutes: 30),
            isPremium: false,
          ),
        ];
      case 'White Noise / Pink / Brown':
        return [
          AudioModel(
            id: 'wn1',
            title: 'White Noise',
            url: 'https://example.com/white-noise.mp3',
            category: 'White Noise / Pink / Brown',
            duration: const Duration(hours: 1),
            isPremium: false,
          ),
          AudioModel(
            id: 'wn2',
            title: 'Pink Noise',
            url: 'https://example.com/pink-noise.mp3',
            category: 'White Noise / Pink / Brown',
            duration: const Duration(hours: 1),
            isPremium: true,
          ),
          AudioModel(
            id: 'wn3',
            title: 'Brown Noise',
            url: 'https://example.com/brown-noise.mp3',
            category: 'White Noise / Pink / Brown',
            duration: const Duration(hours: 1),
            isPremium: false,
          ),
        ];
      default:
        return [];
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'waves':
        return Icons.graphic_eq;
      case 'cloud':
        return Icons.cloud;
      case 'dots':
        return Icons.grain;
      case 'meditation':
        return Icons.self_improvement;
      case 'sleep':
        return Icons.bedtime;
      default:
        return Icons.music_note;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E), // Fundo escuro similar à imagem
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Navegar para perfil
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header da categoria
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2B3E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(widget.categoryIcon),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.categoryName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.categoryDescription,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de músicas
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categoryAudios.length,
                    itemBuilder: (context, index) {
                      final audio = categoryAudios[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2B3E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3B4E),
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
                            _formatDuration(audio.duration),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (audio.isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _handleDownload(context, audio);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _handlePlay(context, audio);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _handlePlay(BuildContext context, AudioModel audio) async {
    if (audio.isPremium) {
      final paywallProvider = Provider.of<PaywallProvider>(context, listen: false);
      await paywallProvider.loadData();
      
      if (!paywallProvider.isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${audio.title} é um áudio premium. Assine para ouvir!'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }
    }
    
    Provider.of<AudioProvider>(context, listen: false).playAudio(context, audio);
    context.go('/player');
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
        SnackBar(
          content: Text('${audio.title} já foi baixado.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    if (audio.isPremium && !paywallProvider.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assine o plano premium para baixar ${audio.title}.'),
          backgroundColor: Colors.amber,
        ),
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
        SnackBar(
          content: Text('Baixando ${fileName}...'),
          backgroundColor: Colors.blue,
        ),
      );
      await downloadService.downloadAudio(url, fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${fileName} baixado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao baixar ${fileName}: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("Erro no download: $e");
    }
  }
}

