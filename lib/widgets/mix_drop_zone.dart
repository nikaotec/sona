import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sona/model/audio_model.dart';

class MixDropZone extends StatefulWidget {
  final Function(AudioModel) onAudioDropped;
  final List<AudioModel> currentMix;
  final bool isExpanded;
  final VoidCallback? onTapToPlay; // Novo callback para abrir player

  const MixDropZone({
    super.key,
    required this.onAudioDropped,
    required this.currentMix,
    this.isExpanded = false,
    this.onTapToPlay,
  });

  @override
  State<MixDropZone> createState() => _MixDropZoneState();
}

class _MixDropZoneState extends State<MixDropZone>
    with TickerProviderStateMixin {
  bool _isDragOver = false;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Inicia animação de pulso se há itens no mix
    if (widget.currentMix.isNotEmpty) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MixDropZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMix.length != oldWidget.currentMix.length) {
      if (widget.currentMix.isNotEmpty) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      child: _buildDropZone(),
      builder: (context, child) {
        return Transform.scale(
          scale: _isDragOver ? _scaleAnimation.value : _pulseAnimation.value,
          child: child,
        );
      },
    );
  }

  Widget _buildDropZone() {
    return DragTarget<AudioModel>(
      onWillAccept: (data) {
        if (data == null) return false;
        
        // Verifica se o áudio já está no mix
        final isAlreadyInMix = widget.currentMix.any((audio) => audio.id == data.id);
        return !isAlreadyInMix;
      },
      onAccept: (data) {
        widget.onAudioDropped(data);
        _scaleController.forward().then((_) {
          _scaleController.reverse();
        });
        HapticFeedback.mediumImpact();
      },
      onMove: (details) {
        if (!_isDragOver) {
          setState(() {
            _isDragOver = true;
          });
          _scaleController.forward();
        }
      },
      onLeave: (data) {
        setState(() {
          _isDragOver = false;
        });
        _scaleController.reverse();
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: widget.currentMix.isNotEmpty && widget.onTapToPlay != null 
              ? widget.onTapToPlay 
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: widget.isExpanded ? 180 : 100, // Reduzido de 120 para 100
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduzido margin vertical
            decoration: BoxDecoration(
              gradient: _isDragOver
                  ? const LinearGradient(
                      colors: [Color(0xFF6B73FF), Color(0xFF9644FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : widget.currentMix.isNotEmpty
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF6B73FF).withOpacity(0.3),
                            const Color(0xFF9644FF).withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
              color: _isDragOver
                  ? null
                  : widget.currentMix.isEmpty
                      ? const Color(0xFF2A2A3E)
                      : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isDragOver
                    ? Colors.white
                    : widget.currentMix.isNotEmpty
                        ? const Color(0xFF6B73FF)
                        : Colors.white.withOpacity(0.2),
                width: _isDragOver ? 3 : 2,
                style: widget.currentMix.isEmpty && !_isDragOver
                    ? BorderStyle.solid
                    : BorderStyle.solid,
              ),
              boxShadow: _isDragOver || widget.currentMix.isNotEmpty
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6B73FF).withOpacity(0.4),
                        blurRadius: _isDragOver ? 25 : 15,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: widget.currentMix.isEmpty
                ? _buildEmptyState()
                : _buildMixPreview(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDragOver
                ? Colors.white.withOpacity(0.2)
                : const Color(0xFF6B73FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            _isDragOver ? Icons.add_circle : Icons.queue_music,
            color: Colors.white,
            size: _isDragOver ? 32 : 28,
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: Text(
            _isDragOver
                ? 'Solte aqui para adicionar'
                : 'Arraste sons para criar seu mix',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: _isDragOver ? 14 : 13,
              fontWeight: _isDragOver ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!_isDragOver) ...[
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              'Combine diferentes sons para relaxar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMixPreview() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.queue_music,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meu Mix (${widget.currentMix.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isDragOver
                          ? 'Solte para adicionar mais'
                          : 'Toque para testar o mix',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.currentMix.isNotEmpty && !_isDragOver)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.isExpanded
                ? _buildExpandedMixList()
                : _buildCompactMixList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMixList() {
    return Column(
      children: [
        // Primeira linha com até 2 músicas
        if (widget.currentMix.isNotEmpty)
          Row(
            children: widget.currentMix.take(2).map((audio) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          audio.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        
        // Segunda linha com mais músicas se houver
        if (widget.currentMix.length > 2)
          Row(
            children: [
              if (widget.currentMix.length > 2)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.currentMix[2].title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Indicador de mais músicas
              if (widget.currentMix.length > 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B73FF).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${widget.currentMix.length - 3}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildExpandedMixList() {
    return ListView.builder(
      itemCount: widget.currentMix.length,
      itemBuilder: (context, index) {
        final audio = widget.currentMix[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  audio.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
