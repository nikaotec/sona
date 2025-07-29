// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:provider/provider.dart';
// import 'package:go_router/go_router.dart';
// import 'package:sona/provider/enhanced_audio_provider.dart';
// import 'package:sona/model/audio_model.dart';
// import 'package:sona/components/expectromi/audio_visualizer/visualizer_manager.dart';

// class FloatingMixPlayer extends StatefulWidget {
//   const FloatingMixPlayer({super.key});

//   @override
//   State<FloatingMixPlayer> createState() => _FloatingMixPlayerState();
// }

// class _FloatingMixPlayerState extends State<FloatingMixPlayer> 
//     with TickerProviderStateMixin {
  
//   bool _isExpanded = false;
//   late AnimationController _expandController;
//   late AnimationController _slideController;
//   late Animation<double> _expandAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
    
//     _expandController = AnimationController(
//       duration: const Duration(milliseconds: 400),
//       vsync: this,
//     );
    
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
    
//     _expandAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _expandController,
//       curve: Curves.easeInOut,
//     ));
    
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOutCubic,
//     ));
    
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _expandController,
//       curve: Curves.easeInOut,
//     ));
    
//     _slideController.forward();
//   }

//   @override
//   void dispose() {
//     _expandController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   void _toggleExpanded() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//     });
    
//     if (_isExpanded) {
//       _expandController.forward();
//     } else {
//       _expandController.reverse();
//     }
    
//     HapticFeedback.lightImpact();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<EnhancedAudioProvider>(
//       builder: (context, audioProvider, child) {
//         if (!audioProvider.hasMixActive) {
//           return const SizedBox.shrink();
//         }

//         final screenHeight = MediaQuery.of(context).size.height;
//         final screenWidth = MediaQuery.of(context).size.width;
        
//         return SlideTransition(
//           position: _slideAnimation,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 400),
//             curve: Curves.easeInOut,
//             height: _isExpanded ? screenHeight * 0.8 : 80,
//             width: screenWidth,
//             margin: EdgeInsets.only(
//               left: 16,
//               right: 16,
//               bottom: _isExpanded ? 0 : 16,
//             ),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   const Color(0xFF2A2A3E),
//                   const Color(0xFF1A1A2E),
//                   if (_isExpanded) const Color(0xFF0F0F1E),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(_isExpanded ? 0 : 16),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF6B73FF).withOpacity(0.2),
//                   blurRadius: 20,
//                   offset: const Offset(0, -4),
//                 ),
//               ],
//               border: Border.all(
//                 color: const Color(0xFF6B73FF).withOpacity(0.3),
//                 width: 1,
//               ),
//             ),
//             child: _isExpanded 
//                 ? _buildExpandedPlayer(audioProvider)
//                 : _buildCompactPlayer(audioProvider),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildCompactPlayer(EnhancedAudioProvider audioProvider) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: _toggleExpanded,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           child: Row(
//             children: [
//               // Visualizador compacto
//               Container(
//                 width: 56,
//                 height: 56,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF6B73FF).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: const Color(0xFF6B73FF).withOpacity(0.3),
//                   ),
//                 ),
//                 child: Center(
//                   child: VisualizerManager(
//                     isPlaying: audioProvider.isAnyMixPlaying,
//                     size: 40,
//                     primaryColor: const Color(0xFF6B73FF),
//                     secondaryColor: const Color(0xFF9644FF),
//                     allowTypeChange: false,
//                     isCompact: true,
//                   ),
//                 ),
//               ),
              
//               const SizedBox(width: 16),
              
//               // Informações do mix
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.queue_music,
//                           color: Color(0xFF6B73FF),
//                           size: 16,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           'Mix Ativo',
//                           style: TextStyle(
//                             color: const Color(0xFF6B73FF),
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       '${audioProvider.mixTracks.length} faixa${audioProvider.mixTracks.length > 1 ? 's' : ''} • ${audioProvider.isAnyMixPlaying ? 'Tocando' : 'Pausado'}',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Controles compactos
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Volume master compacto
//                   Container(
//                     width: 60,
//                     child: SliderTheme(
//                       data: SliderTheme.of(context).copyWith(
//                         activeTrackColor: const Color(0xFF6B73FF),
//                         inactiveTrackColor: Colors.white24,
//                         thumbColor: const Color(0xFF6B73FF),
//                         thumbShape: const RoundSliderThumbShape(
//                           enabledThumbRadius: 6,
//                         ),
//                         trackHeight: 3,
//                         overlayShape: SliderComponentShape.noOverlay,
//                       ),
//                       child: Slider(
//                         value: audioProvider.masterVolume,
//                         min: 0.0,
//                         max: 1.0,
//                         onChanged: (value) {
//                           audioProvider.setMasterVolume(value);
//                           HapticFeedback.lightImpact();
//                         },
//                       ),
//                     ),
//                   ),
                  
//                   const SizedBox(width: 8),
                  
//                   // Botão play/pause
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF6B73FF),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Material(
//                       color: Colors.transparent,
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(8),
//                         onTap: () {
//                           if (audioProvider.isAnyMixPlaying) {
//                             audioProvider.pauseAll();
//                           } else {
//                             audioProvider.playAll();
//                           }
//                           HapticFeedback.mediumImpact();
//                         },
//                         child: Icon(
//                           audioProvider.isAnyMixPlaying ? Icons.pause : Icons.play_arrow,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ),
                  
//                   const SizedBox(width: 8),
                  
//                   // Botão expandir
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Material(
//                       color: Colors.transparent,
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(8),
//                         onTap: _toggleExpanded,
//                         child: const Icon(
//                           Icons.expand_less,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildExpandedPlayer(EnhancedAudioProvider audioProvider) {
//     return Column(
//       children: [
//         // Header expandido
//         _buildExpandedHeader(audioProvider),
        
//         // Visualizador central
//         _buildExpandedVisualizer(audioProvider),
        
//         // Lista de faixas
//         Expanded(
//           child: _buildExpandedTracksList(audioProvider),
//         ),
        
//         // Controles expandidos
//         _buildExpandedControls(audioProvider),
//       ],
//     );
//   }

//   Widget _buildExpandedHeader(EnhancedAudioProvider audioProvider) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         child: Row(
//           children: [
//             // Botão minimizar
//             IconButton(
//               onPressed: _toggleExpanded,
//               icon: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.expand_more,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
            
//             // Título
//             const Expanded(
//               child: Text(
//                 'Mix Player',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
            
//             // Botão para tela completa
//             IconButton(
//               onPressed: () {
//                 context.go('/mix-player');
//                 _toggleExpanded();
//               },
//               icon: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF6B73FF).withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.open_in_full,
//                   color: Color(0xFF6B73FF),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExpandedVisualizer(EnhancedAudioProvider audioProvider) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Container(
//         height: 120,
//         margin: const EdgeInsets.symmetric(horizontal: 20),
//         child: Center(
//           child: VisualizerManager(
//             isPlaying: audioProvider.isAnyMixPlaying,
//             size: 100,
//             primaryColor: const Color(0xFF6B73FF),
//             secondaryColor: const Color(0xFF9644FF),
//             allowTypeChange: true,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildExpandedTracksList(EnhancedAudioProvider audioProvider) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header da lista
//             Row(
//               children: [
//                 const Text(
//                   'Faixas Ativas',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   '${audioProvider.mixTracks.length} faixa${audioProvider.mixTracks.length > 1 ? 's' : ''}',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.7),
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 12),
            
//             // Lista de faixas
//             Expanded(
//               child: ListView.builder(
//                 itemCount: audioProvider.mixTracks.length,
//                 itemBuilder: (context, index) {
//                   final track = audioProvider.mixTracks[index];
//                   return _buildExpandedTrackCard(track, audioProvider);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExpandedTrackCard(MixTrack track, EnhancedAudioProvider audioProvider) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: track.isPlaying 
//               ? const Color(0xFF6B73FF).withOpacity(0.5)
//               : Colors.white.withOpacity(0.1),
//         ),
//       ),
//       child: Row(
//         children: [
//           // Ícone da categoria
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: const Color(0xFF6B73FF).withOpacity(0.2),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Icon(
//               _getCategoryIcon(track.audio.category),
//               color: const Color(0xFF6B73FF),
//               size: 16,
//             ),
//           ),
          
//           const SizedBox(width: 12),
          
//           // Informações da música
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   track.audio.title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 Text(
//                   track.audio.category,
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.7),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // Controle de volume compacto
//           Container(
//             width: 60,
//             child: SliderTheme(
//               data: SliderTheme.of(context).copyWith(
//                 activeTrackColor: const Color(0xFF6B73FF),
//                 inactiveTrackColor: Colors.white24,
//                 thumbColor: const Color(0xFF6B73FF),
//                 thumbShape: const RoundSliderThumbShape(
//                   enabledThumbRadius: 6,
//                 ),
//                 trackHeight: 3,
//                 overlayShape: SliderComponentShape.noOverlay,
//               ),
//               child: Slider(
//                 value: track.volume,
//                 min: 0.0,
//                 max: 1.0,
//                 onChanged: (value) {
//                   audioProvider.setMixTrackVolume(track.audio.id, value);
//                   HapticFeedback.lightImpact();
//                 },
//               ),
//             ),
//           ),
          
//           // Botão play/pause
//           IconButton(
//             onPressed: () => audioProvider.toggleMixTrack(track.audio.id),
//             icon: Icon(
//               track.isPlaying ? Icons.pause : Icons.play_arrow,
//               color: const Color(0xFF6B73FF),
//               size: 20,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildExpandedControls(EnhancedAudioProvider audioProvider) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             // Volume master
//             Row(
//               children: [
//                 const Icon(
//                   Icons.volume_up,
//                   color: Color(0xFF6B73FF),
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Volume Master',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   '${(audioProvider.masterVolume * 100).round()}%',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 8),
            
//             SliderTheme(
//               data: SliderTheme.of(context).copyWith(
//                 activeTrackColor: const Color(0xFF6B73FF),
//                 inactiveTrackColor: Colors.white24,
//                 thumbColor: const Color(0xFF6B73FF),
//                 thumbShape: const RoundSliderThumbShape(
//                   enabledThumbRadius: 8,
//                 ),
//                 trackHeight: 4,
//                 overlayShape: SliderComponentShape.noOverlay,
//               ),
//               child: Slider(
//                 value: audioProvider.masterVolume,
//                 min: 0.0,
//                 max: 1.0,
//                 onChanged: (value) {
//                   audioProvider.setMasterVolume(value);
//                   HapticFeedback.lightImpact();
//                 },
//               ),
//             ),
            
//             const SizedBox(height: 16),
            
//             // Controles principais
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // Pausar tudo
//                 _buildExpandedControlButton(
//                   icon: Icons.pause,
//                   onPressed: () {
//                     audioProvider.pauseAll();
//                     HapticFeedback.mediumImpact();
//                   },
//                   color: Colors.orange,
//                 ),
                
//                 // Play/Pause geral
//                 _buildExpandedControlButton(
//                   icon: audioProvider.isAnyMixPlaying ? Icons.pause : Icons.play_arrow,
//                   onPressed: () {
//                     if (audioProvider.isAnyMixPlaying) {
//                       audioProvider.pauseAll();
//                     } else {
//                       audioProvider.playAll();
//                     }
//                     HapticFeedback.mediumImpact();
//                   },
//                   color: const Color(0xFF6B73FF),
//                   isPrimary: true,
//                 ),
                
//                 // Parar tudo
//                 _buildExpandedControlButton(
//                   icon: Icons.stop,
//                   onPressed: () {
//                     audioProvider.stopAll();
//                     HapticFeedback.heavyImpact();
//                   },
//                   color: Colors.red,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExpandedControlButton({
//     required IconData icon,
//     required VoidCallback onPressed,
//     required Color color,
//     bool isPrimary = false,
//   }) {
//     return Container(
//       width: isPrimary ? 56 : 48,
//       height: isPrimary ? 56 : 48,
//       decoration: BoxDecoration(
//         color: color,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.3),
//             blurRadius: isPrimary ? 12 : 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(28),
//           onTap: onPressed,
//           child: Icon(
//             icon,
//             color: Colors.white,
//             size: isPrimary ? 28 : 24,
//           ),
//         ),
//       ),
//     );
//   }

//   IconData _getCategoryIcon(String category) {
//     switch (category.toLowerCase()) {
//       case 'natureza':
//         return Icons.nature;
//       case 'binaural':
//         return Icons.graphic_eq;
//       case 'instrumental':
//         return Icons.music_note;
//       case 'meditação':
//         return Icons.self_improvement;
//       case 'relaxamento':
//         return Icons.spa;
//       case 'white noise':
//         return Icons.blur_on;
//       case 'sleep':
//         return Icons.nightlight_round;
//       default:
//         return Icons.music_note;
//     }
//   }
// }
