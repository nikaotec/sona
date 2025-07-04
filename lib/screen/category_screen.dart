import 'package:flutter/material.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/audio_download_service.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados das categorias baseados na imagem de referência
    final categories = [
      {
        'name': 'Binaural Beats',
        'description': 'Brainwave entrainment',
        'icon': 'waves',
        'iconData': Icons.graphic_eq,
      },
      {
        'name': 'Nature Sounds',
        'description': 'Rain, Ocean, Wind, and more',
        'icon': 'cloud',
        'iconData': Icons.cloud,
      },
      {
        'name': 'White Noise / Pink / Brown',
        'description': 'Ambient noise generators',
        'icon': 'dots',
        'iconData': Icons.grain,
      },
      {
        'name': 'Guided Meditations',
        'description': 'Mindfulness and relaxation',
        'icon': 'meditation',
        'iconData': Icons.self_improvement,
      },
      {
        'name': 'Sleep',
        'description': 'Mixes for deep sleep',
        'icon': 'sleep',
        'iconData': Icons.bedtime,
      },
    ];

    // Áudios populares para a seção inferior
    final popularAudios = [
      AudioModel(
        id: '1',
        title: 'Tranquil Pond',
        url: 'https://example.com/audio1.mp3',
        category: 'Nature Mix',
        duration: const Duration(minutes: 10),
      ),
      AudioModel(
        id: '2',
        title: 'Serenity',
        url: 'https://example.com/audio2.mp3',
        category: 'Sleep Mix',
        duration: const Duration(minutes: 10),
        isPremium: true,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E), // Fundo escuro da imagem
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
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
              // Navegar para perfil
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título Categories
              const Text(
                'Categories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Lista de categorias
              ...categories.map((category) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2B3E), // Cor dos cards
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
                      child: Icon(
                        category['iconData'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      category['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      category['description'] as String,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 24,
                    ),
                    onTap: () {
                      // Navegar para a tela de listagem de músicas da categoria
                      context.push(
                        '/category-music-list',
                        extra: {
                          'categoryName': category['name'],
                          'categoryIcon': category['icon'],
                          'categoryDescription': category['description'],
                        },
                      );
                    },
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
              
              // Grid de áudios populares
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: popularAudios.length,
                itemBuilder: (context, index) {
                  final audio = popularAudios[index];
                  return GestureDetector(
                    onTap: () {
                      _handlePlay(context, audio);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: index == 0
                            ? const LinearGradient(
                                colors: [Color(0xFF4A6741), Color(0xFF2D4A2B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF4A3D7A), Color(0xFF2D2A4A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              audio.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              audio.category,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Player mini na parte inferior (simulando o da imagem)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2B3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
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
                        // Lógica de play/pause
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
          ),
        ),
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

