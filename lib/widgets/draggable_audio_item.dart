import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sona/model/audio_model.dart';

class DraggableAudioItem extends StatefulWidget {
  final AudioModel audio;
  final VoidCallback? onTap;
  final VoidCallback? onPreview;
  final bool isSelected;
  final bool isInMix;
  final int index;

  const DraggableAudioItem({
    super.key,
    required this.audio,
    this.onTap,
    this.onPreview,
    this.isSelected = false,
    this.isInMix = false,
    required this.index,
  });

  @override
  State<DraggableAudioItem> createState() => _DraggableAudioItemState();
}

class _DraggableAudioItemState extends State<DraggableAudioItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isInMix) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DraggableAudioItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInMix != oldWidget.isInMix) {
      if (widget.isInMix) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isDragging 
              ? _scaleAnimation.value 
              : (widget.isInMix ? _pulseAnimation.value : 1.0),
          child: LongPressDraggable<AudioModel>(
            data: widget.audio,
            feedback: _buildFeedback(),
            childWhenDragging: _buildChildWhenDragging(),
            delay: const Duration(milliseconds: 300), // Delay para permitir scroll
            hapticFeedbackOnStart: true,
            onDragStarted: () {
              setState(() {
                _isDragging = true;
              });
              _scaleController.forward();
              HapticFeedback.mediumImpact();
            },
            onDragEnd: (details) {
              setState(() {
                _isDragging = false;
              });
              _scaleController.reverse();
            },
            child: _buildAudioItem(),
          ),
        );
      },
    );
  }

  Widget _buildAudioItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: widget.isSelected || widget.isInMix
                  ? const LinearGradient(
                      colors: [Color(0xFF6B73FF), Color(0xFF9644FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isSelected || widget.isInMix 
                  ? null 
                  : const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected || widget.isInMix
                    ? const Color(0xFF6B73FF)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: widget.isInMix
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6B73FF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Ícone do áudio com indicador de drag
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.isSelected || widget.isInMix
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF6B73FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          widget.isInMix 
                              ? Icons.queue_music 
                              : widget.isSelected 
                                  ? Icons.check 
                                  : Icons.music_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      // Indicador de drag melhorado
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.drag_handle,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informações do áudio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.audio.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            widget.audio.category,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!widget.isInMix && !widget.isSelected) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B73FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Pressione e segure',
                                style: TextStyle(
                                  color: Color(0xFF6B73FF),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (widget.isInMix) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No Mix',
                                style: TextStyle(
                                  color: Colors.white,
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
                
                // Botão de preview
                IconButton(
                  icon: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: widget.onPreview,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: widget.index * 50))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildFeedback() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B73FF), Color(0xFF9644FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B73FF).withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.audio.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Arraste para o mix',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildWhenDragging() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white38,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.audio.title,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.audio.category,
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
