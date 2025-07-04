import 'package:flutter/material.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/paywall_provider.dart';
import 'package:sona/service/ad_service.dart';
import 'package:sona/service/audio_download_service.dart'; // Caminho corrigido

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleAudios = [
      AudioModel(
        id: '1',
        title: 'Tranquil Pond',
        url: 'https://example.com/audio1.mp3',
        category: 'Nature Sounds',
        duration: const Duration(minutes: 10),
      ),
      AudioModel(
        id: '2',
        title: 'Body Scan',
        url: 'https://example.com/audio2.mp3',
        category: 'Guided Meditations',
        duration: const Duration(minutes: 10),
        isPremium: true,
      ),
      AudioModel(
        id: '3',
        title: 'Binaural Beats Delta',
        url: 'assets/music/bineural/binaural-beats_delta_440_440-5hz-48565.mp3',
        category: 'Binaural Beats',
        duration: const Duration(minutes: 5), // Placeholder duration
        isPremium: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MindWave')),
      body: ListView(
        children: sampleAudios.map((audio) {
          return ListTile(
            title: Text(audio.title),
            subtitle: Text(audio.category),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (audio.isPremium)
                  const Icon(Icons.lock)
                else
                  // Ícone de Play removido daqui para evitar confusão,
                  // já que o onTap no ListTile já faz isso.
                  // Considerar se o ícone de play é realmente necessário aqui se o tile inteiro é clicável.
                  // Por ora, vamos focar no botão de download.
                  const SizedBox.shrink(), // Ou mantenha o play_arrow se preferir
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // Lógica de download com anúncio será implementada aqui
                    _handleDownload(context, audio);
                  },
                ),
              ],
            ),
            onTap: () async {
              if (audio.isPremium) {
                // TODO: Lógica para lidar com áudio premium (ex: mostrar paywall)
                // Por enquanto, vamos apenas impedir a reprodução ou fazer um print
                debugPrint("Tentativa de tocar áudio premium: ${audio.title}");
                // Ou, se o PaywallProvider já lida com isso no playAudio, pode chamar direto.
                // Assumindo que playAudio já tem lógica de paywall para áudios premium:
                // Provider.of<AudioProvider>(context, listen: false).playAudio(context, audio);
                // context.go('/player');
                // Por ora, para focar no download, vamos apenas exibir uma mensagem.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${audio.title} é um áudio premium. Assine para ouvir e baixar!')),
                );
                return;
              }
              Provider.of<AudioProvider>(context, listen: false)
                  .playAudio(context, audio);
              context.go('/player');
            },
          );
        }).toList(),
      ),
    );
  }

  void _handleDownload(BuildContext context, AudioModel audio) async {
    // Obter os providers necessários
    final paywallProvider = Provider.of<PaywallProvider>(context, listen: false);
    final adService = Provider.of<AdService>(context, listen: false);
    final audioDownloadService = Provider.of<AudioDownloadService>(context, listen: false);

    // Carregar dados do paywall (importante para saber o status premium)
    await paywallProvider.loadData();

    // Nome do arquivo para salvar (ex: "Tranquil Pond.mp3")
    // É importante que o AudioModel tenha uma propriedade para o nome do arquivo ou uma forma de derivá-lo.
    // Assumindo que audio.title é único e adequado para nome de arquivo.
    // Adicionar extensão .mp3 se não estiver na URL ou título.
    final String fileName = "${audio.title.replaceAll(' ', '_')}.mp3"; // Simples exemplo de nome de arquivo

    // Verificar se o áudio já foi baixado
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
      // Opcionalmente, navegar para a tela de paywall:
      // context.go('/paywall');
      return;
    }

    // Lógica para exibir anúncio se não for premium
    if (!paywallProvider.isPremium) {
      adService.showRewardedAd(
        onUserEarnedRewardCallback: () {
          debugPrint("Usuário ganhou recompensa por assistir anúncio antes do download.");
          // Aqui você pode, por exemplo, registrar que o usuário ganhou "créditos de download" se aplicável.
        },
        onAdDismissed: () {
          debugPrint("Anúncio dispensado, iniciando download.");
          _performDownload(context, audioDownloadService, audio.url, fileName);
        },
        onAdFailedToLoadOrShow: (error) {
          debugPrint("Falha ao carregar/mostrar anúncio para download: $error. Permitindo download mesmo assim.");
          // Decisão de negócios: permitir download mesmo se anúncio falhar?
          // Por ora, vamos permitir.
          _performDownload(context, audioDownloadService, audio.url, fileName);
        },
      );
    } else {
      // Usuário premium, baixa diretamente
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
