import 'package:flutter/material.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MindWave')),
      body: ListView(
        children: sampleAudios.map((audio) {
          return ListTile(
            title: Text(audio.title),
            subtitle: Text(audio.category),
            trailing: audio.isPremium
                ? const Icon(Icons.lock)
                : const Icon(Icons.play_arrow),
            onTap: () {
              Provider.of<AudioProvider>(context, listen: false)
                  .playAudio(context, audio);
              context.go('/player');
            },
          );
        }).toList(),
      ),
    );
  }
}
