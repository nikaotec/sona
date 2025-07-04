import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:sona/provider/user_data_provider.dart';
import 'package:sona/widgtes/audio_timer.dart';
import 'package:sona/service/ad_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AdService _adService;

  @override
  void initState() {
    super.initState();
    _adService = Provider.of<AdService>(context, listen: false);
    _adService.loadInterstitialAd();
    _adService.loadRewardedAd();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);
    final audio = provider.currentAudio;
    final userData = Provider.of<UserDataProvider>(context);
    final isFav = userData.favorites.any((a) => a.id == audio?.id);

    if (audio == null) {
      return const Scaffold(body: Center(child: Text('Nenhum áudio selecionado')));
    }

    Provider.of<UserDataProvider>(context, listen: false).saveToHistory(audio);

    return Scaffold(
      appBar: AppBar(title: Text(audio.title)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(audio.title, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
            iconSize: 64,
            onPressed: () {
              provider.isPlaying ? provider.pauseAudio() : provider.playAudio(context, audio);
            },
          ),
          Text('${audio.duration.inMinutes} minutos'),
          AudioTimer(
            onTimerComplete: () {
              provider.pauseAudio(); // Ou provider.stopAudio();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timer finalizado. Áudio pausado.')),
              );
              _adService.showInterstitialAd(); // Show interstitial ad when audio finishes
            },
          ),
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            onPressed: () => userData.toggleFavorite(audio),
          ),
          if (audio.isPremium) // Show rewarded ad button for premium content
            ElevatedButton(
              onPressed: () {
                _adService.showRewardedAd(() {
                  // Reward the user, e.g., unlock premium content temporarily
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conteúdo premium desbloqueado temporariamente!')), 
                  );
                });
              },
              child: const Text('Assista a um anúncio para desbloquear'),
            ),
        ],
      ),
    );
  }
}


