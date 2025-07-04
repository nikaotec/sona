import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:sona/provider/user_data_provider.dart';
import 'package:sona/widgtes/audio_timer.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _saved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // if (!_saved) {
    //   final audio = Provider.of<AudioProvider>(context, listen: false).currentAudio;
    //   if (audio != null) {
    //     Provider.of<UserDataProvider>(context, listen: false).saveToHistory(audio);
    //     _saved = true;
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    final audio = provider.currentAudio;

    if (audio == null) {
      return const Scaffold(body: Center(child: Text('Nenhum áudio selecionado')));
    }

    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final isFav = userData.favorites.any((a) => a.id == audio.id);

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
              provider.isPlaying
                  ? provider.pauseAudio()
                  : provider.playAudio(context, audio);
            },
          ),
          Text('${audio.duration.inMinutes} minutos'),
          AudioTimer(
            onTimerComplete: () {
              provider.pauseAudio();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timer finalizado. Áudio pausado.')),
              );
            },
          ),
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            onPressed: () => userData.toggleFavorite(audio),
          ),
        ],
      ),
    );
  }
}
