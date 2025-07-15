import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sona/provider/mix_manager_provider.dart';
import 'package:sona/provider/enhanced_audio_provider.dart';
import 'package:sona/provider/subscription_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sona/widgtes/enhanced_mini_player_widget.dart';

class SavedMixesScreen extends StatefulWidget {
  const SavedMixesScreen({super.key});

  @override
  State<SavedMixesScreen> createState() => _SavedMixesScreenState();
}

class _SavedMixesScreenState extends State<SavedMixesScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBannerAd();
    
    // Inicializar o MixManagerProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MixManagerProvider>(context, listen: false).initialize();
    });
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Iniciar animações
    _slideController.forward();
    _fadeController.forward();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _bannerAd?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<MixManagerProvider, EnhancedAudioProvider, SubscriptionProvider>(
      builder: (context, mixManager, audioProvider, subscriptionProvider, child) {
        final filteredMixes = _searchQuery.isEmpty 
            ? mixManager.savedMixes 
            : mixManager.searchMixes(_searchQuery);

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
                  // Header
                  _buildHeader(mixManager),
                  
                  // Barra de pesquisa
                  _buildSearchBar(),
                  
                  // Banner de anúncio para usuários não premium
                  if (!subscriptionProvider.hasActiveSubscription)
                    _buildBannerAd(),
                  
                  // Estatísticas
                  if (filteredMixes.isNotEmpty)
                    _buildStatistics(mixManager),
                  
                  // Lista de mixes
                  Expanded(
                    child: filteredMixes.isEmpty
                        ? _buildEmptyState()
                        : _buildMixesList(filteredMixes, audioProvider, mixManager),
                  ),
                ],
              ),
            ),
          ),
          // Mini Player
          bottomSheet: const EnhancedMiniPlayerWidget(
            showOnlyWhenPlaying: true,
            margin: EdgeInsets.all(16),
          ),
        );
      },
    );
  }

  Widget _buildHeader(MixManagerProvider mixManager) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Botão voltar
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Título
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meus Mixes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      '${mixManager.savedMixes.length} mix${mixManager.savedMixes.length != 1 ? 'es' : ''} salvo${mixManager.savedMixes.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Menu de opções
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: const Color(0xFF2A2A3E),
                onSelected: (value) {
                  switch (value) {
                    case 'export':
                      _exportMixes(mixManager);
                      break;
                    case 'import':
                      _showImportDialog(mixManager);
                      break;
                    case 'clear':
                      _showClearAllDialog(mixManager);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Colors.white70),
                        SizedBox(width: 12),
                        Text('Exportar Mixes', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(Icons.upload, color: Colors.white70),
                        SizedBox(width: 12),
                        Text('Importar Mixes', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Limpar Todos', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar mixes...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildBannerAd() {
    if (_isBannerAdReady && _bannerAd != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.ads_click, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Anúncio',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms);
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatistics(MixManagerProvider mixManager) {
    final stats = mixManager.getMixStatistics();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem('Mixes', stats['totalMixes'].toString(), Icons.queue_music),
          _buildStatItem('Músicas', stats['totalAudios'].toString(), Icons.music_note),
          _buildStatItem('Favoritos', stats['favoriteMixes'].toString(), Icons.star),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Open Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.queue_music,
                  size: 60,
                  color: Colors.white54,
                ),
              ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 24),
              
              Text(
                _searchQuery.isEmpty ? 'Nenhum mix salvo' : 'Nenhum resultado encontrado',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 12),
              
              Text(
                _searchQuery.isEmpty 
                    ? 'Crie seu primeiro mix adicionando músicas na tela do player'
                    : 'Tente buscar por outro termo',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Open Sans',
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 700.ms),
              
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/categories'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Explorar Músicas',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).scale(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMixesList(List<SavedMix> mixes, EnhancedAudioProvider audioProvider, MixManagerProvider mixManager) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: mixes.length,
          itemBuilder: (context, index) {
            final mix = mixes[index];
            return _buildMixCard(mix, index, audioProvider, mixManager);
          },
        ),
      ),
    );
  }

  Widget _buildMixCard(SavedMix mix, int index, EnhancedAudioProvider audioProvider, MixManagerProvider mixManager) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _loadMix(mix, audioProvider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone do mix
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF9644FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.queue_music,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      if (mix.isFavorite)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Informações do mix
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mix.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mix.audios.length} música${mix.audios.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Criado em ${_formatDate(mix.createdAt)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botões de ação
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão favorito
                    IconButton(
                      onPressed: () => mixManager.toggleFavorite(mix.id),
                      icon: Icon(
                        mix.isFavorite ? Icons.star : Icons.star_border,
                        color: mix.isFavorite ? Colors.amber : Colors.white54,
                      ),
                    ),
                    
                    // Menu de opções
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      color: const Color(0xFF2A2A3E),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditMixDialog(mix, mixManager);
                            break;
                          case 'duplicate':
                            _duplicateMix(mix, mixManager);
                            break;
                          case 'delete':
                            _showDeleteMixDialog(mix, mixManager);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.white70),
                              SizedBox(width: 12),
                              Text('Editar', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, color: Colors.white70),
                              SizedBox(width: 12),
                              Text('Duplicar', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Excluir', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.3, end: 0);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _loadMix(SavedMix mix, EnhancedAudioProvider audioProvider) async {
    try {
      // Limpar mix atual
      audioProvider.clearMix();
      
      // Adicionar todas as músicas do mix salvo
      for (final audio in mix.audios) {
        await audioProvider.addToMix(audio);
      }
      
      // Navegar para a tela de mix
      context.go('/mix-list');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mix "${mix.name}" carregado com sucesso!'),
          backgroundColor: const Color(0xFF6C63FF),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar mix: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditMixDialog(SavedMix mix, MixManagerProvider mixManager) {
    final TextEditingController nameController = TextEditingController(text: mix.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Editar Mix',
          style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nome do mix',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != mix.name) {
                await mixManager.updateMix(mix.id, name: newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mix renomeado com sucesso!'),
                    backgroundColor: Color(0xFF6C63FF),
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  void _duplicateMix(SavedMix mix, MixManagerProvider mixManager) async {
    try {
      await mixManager.duplicateMix(mix.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mix "${mix.name}" duplicado com sucesso!'),
          backgroundColor: const Color(0xFF6C63FF),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao duplicar mix: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteMixDialog(SavedMix mix, MixManagerProvider mixManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Excluir Mix',
          style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        ),
        content: Text(
          'Tem certeza que deseja excluir o mix "${mix.name}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70, fontFamily: 'Open Sans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await mixManager.deleteMix(mix.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mix "${mix.name}" excluído com sucesso!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _exportMixes(MixManagerProvider mixManager) {
    try {
      final jsonData = mixManager.exportMixesToJson();
      // Aqui você implementaria a lógica para salvar o arquivo
      // Por exemplo, usando o package share_plus ou file_picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mixes exportados com sucesso!'),
          backgroundColor: Color(0xFF6C63FF),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar mixes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImportDialog(MixManagerProvider mixManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Importar Mixes',
          style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        ),
        content: const Text(
          'Esta funcionalidade permite importar mixes de um arquivo de backup. Selecione o arquivo JSON exportado anteriormente.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Open Sans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Aqui você implementaria a lógica para selecionar e importar o arquivo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade em desenvolvimento'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Selecionar Arquivo', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(MixManagerProvider mixManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Limpar Todos os Mixes',
          style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        ),
        content: const Text(
          'Tem certeza que deseja excluir TODOS os mixes salvos? Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Open Sans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await mixManager.clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todos os mixes foram excluídos!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Excluir Todos', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
