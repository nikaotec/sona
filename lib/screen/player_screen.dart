import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sona/provider/audio_provider.dart';
import 'package:sona/components/banner_ad_widget.dart';
import 'package:sona/provider/paywall_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final paywallProvider = Provider.of<PaywallProvider>(context);
    final audio = audioProvider.currentAudio;

    if (audio == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Text(
            'Nenhum áudio selecionado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Use MediaQuery para responsividade
    final screenHeight = MediaQuery.of(context).size.height;
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
              // Header com título do app
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.go('/categories'),
                    ),
                    Expanded(
                      child: Text(
                        'MindWave',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.12), // Para balancear o botão de voltar
                  ],
                ),
              ),
              
              // Banner de anúncio para usuários não premium
              if (!paywallProvider.isPremium)
                const BannerAdWidget(),
              
              // Imagem principal (placeholder para pessoa meditando)
              Expanded(
                flex: 3,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: screenWidth * 0.05,
                        offset: Offset(0, screenWidth * 0.025),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6B73FF),
                            Color(0xFF9644FF),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.self_improvement,
                        size: screenWidth * 0.3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Informações da música e controles
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribui o espaço igualmente
                    children: [
                      // Categoria
                      Text(
                        audio.category,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      // Título da música
                      Text(
                        audio.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Barra de progresso
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF6B73FF),
                                inactiveTrackColor: Colors.white24,
                                thumbColor: const Color(0xFF6B73FF),
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: screenWidth * 0.02,
                                ),
                                trackHeight: screenHeight * 0.005,
                                overlayShape: SliderComponentShape.noOverlay,
                              ),
                              child: Slider(
                                value: audioProvider.currentPosition.inSeconds.toDouble().clamp(
                                  0.0, 
                                  audioProvider.totalDuration.inSeconds.toDouble()
                                ),
                                max: audioProvider.totalDuration.inSeconds.toDouble() > 0 
                                    ? audioProvider.totalDuration.inSeconds.toDouble() 
                                    : 1.0,
                                onChanged: (value) {
                                  audioProvider.seek(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                          ),
                          
                          // Tempos
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(audioProvider.currentPosition),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                                Text(
                                  '-${_formatDuration(audioProvider.totalDuration - audioProvider.currentPosition)}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Controles de reprodução
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Botão anterior
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            iconSize: screenWidth * 0.1,
                            color: Colors.white,
                            onPressed: () {
                              // TODO: Implementar música anterior
                            },
                          ),
                          
                          SizedBox(width: screenWidth * 0.05),
                          
                          // Botão play/pause principal
                          Container(
                            width: screenWidth * 0.2,
                            height: screenWidth * 0.2,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: audioProvider.isLoading
                                ? const CircularProgressIndicator(
                                    color: Color(0xFF1A1A2E),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                                      size: screenWidth * 0.1,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                    onPressed: () {
                                      audioProvider.togglePlayPause(context);
                                    },
                                  ),
                          ),
                          
                          SizedBox(width: screenWidth * 0.05),
                          
                          // Botão próximo
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            iconSize: screenWidth * 0.1,
                            color: Colors.white,
                            onPressed: () {
                              // TODO: Implementar próxima música
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

