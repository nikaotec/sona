import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sona/model/audio_model.dart';
import 'package:sona/provider/subscription_provider.dart';
import 'package:sona/provider/user_data_provider.dart';
import 'package:sona/provider/mix_manager_provider.dart';
import 'package:sona/widgtes/mini_player_widget.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar dados do usuário ao inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserDataProvider>(
        context,
        listen: false,
      ).loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'MindWave',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn().slideX(begin: -0.3, end: 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              context.go('/profile');
            },
          ).animate().fadeIn(delay: 200.ms).scale(),
        ],
      ),
      body: Consumer3<SubscriptionProvider, UserDataProvider, MixManagerProvider>(
        builder: (context, subscriptionProvider, userDataProvider, mixManager, child) {
          final categories = _getOrderedCategories(
            userDataProvider.preferredCategory,
          );
          final popularItems = _getPopularItems();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saudação personalizada
                _buildPersonalizedGreeting(userDataProvider),

                const SizedBox(height: 24),

                // Banner de Assinatura (visível apenas para não-premium)
                if (!subscriptionProvider.hasActiveSubscription) ...[
                  _buildSubscriptionBanner()
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 24),
                ],

                // Seção Seus Mixes (se houver mixes)
                if (mixManager.hasMixes) ...[
                  _buildYourMixesSection(mixManager),
                  const SizedBox(height: 32),
                ],

                // Categoria recomendada (se houver)
                if (userDataProvider.preferredCategory != null) ...[
                  _buildRecommendedSection(userDataProvider, categories),
                  const SizedBox(height: 32),
                ],

                // Título das categorias
                const Text(
                  'Todas as Categorias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3, end: 0),

                const SizedBox(height: 16),

                // Lista de categorias ordenada por preferência
                ...categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isPreferred =
                      category['title'] == userDataProvider.preferredCategory;

                  return _buildCategoryCard(category, index, isPreferred);
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
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3, end: 0),

                const SizedBox(height: 16),

                // Grid de itens populares
                _buildPopularGrid(popularItems),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      // Mini Player flutuante
      bottomSheet: const MiniPlayerWidget(
        showOnlyWhenPlaying: true,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildYourMixesSection(MixManagerProvider mixManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.queue_music,
              color: Color(0xFF6C63FF),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '🎧 Seus Mixes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCreateMixDialog(mixManager),
              icon: const Icon(
                Icons.add,
                color: Color(0xFF6C63FF),
                size: 18,
              ),
              label: const Text(
                'Criar',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.3, end: 0),

        const SizedBox(height: 16),

        // Lista horizontal de mixes
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mixManager.mixes.length + 1, // +1 para o botão de criar
            itemBuilder: (context, index) {
              if (index == mixManager.mixes.length) {
                // Botão de criar novo mix
                return _buildCreateMixCard(mixManager);
              }

              final mix = mixManager.mixes[index];
              return _buildMixCard(mix, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMixCard(dynamic mix, int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.8),
            const Color(0xFF9644FF).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.go('/mix_edit/${mix.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.queue_music,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    if (mix.audios.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${mix.audios.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        mix.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mix.audios.isEmpty 
                            ? 'Vazio' 
                            : '${mix.audios.length} ${mix.audios.length == 1 ? 'música' : 'músicas'}',
                        style: const TextStyle(
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
        ),
      ),
    ).animate(delay: (300 + index * 100).ms).fadeIn().slideX(begin: 0.3, end: 0);
  }

  Widget _buildCreateMixCard(MixManagerProvider mixManager) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCreateMixDialog(mixManager),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF6C63FF),
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Criar Mix',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Novo',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().scale();
  }

  void _showCreateMixDialog(MixManagerProvider mixManager) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Criar Novo Mix',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nome do mix',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Você poderá adicionar músicas ao mix depois de criá-lo.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final mix = await mixManager.createNewMix(name);
                
                if (mounted) {
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mix "$name" criado com sucesso!'),
                      backgroundColor: const Color(0xFF6C63FF),
                      action: SnackBarAction(
                        label: 'Editar',
                        onPressed: () {
                          context.go('/mix_edit/${mix.id}');
                        },
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedGreeting(UserDataProvider userDataProvider) {
    String greeting = 'Bem-vindo ao MindWave';
    String subtitle = 'Explore nossas categorias de relaxamento';

    if (userDataProvider.hasCompletedOnboarding) {
      greeting = _getTimeBasedGreeting();
      subtitle = userDataProvider.getPersonalizedRecommendation();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn().slideY(begin: -0.3, end: 0),

        const SizedBox(height: 8),

        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3, end: 0),
      ],
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom dia!';
    } else if (hour < 18) {
      return 'Boa tarde!';
    } else {
      return 'Boa noite!';
    }
  }

  Widget _buildRecommendedSection(
    UserDataProvider userDataProvider,
    List<Map<String, dynamic>> categories,
  ) {
   final preferredCategory = categories.firstWhere(
      (cat) => cat['title'] == userDataProvider.preferredCategory,
      orElse: () =><String, Object>{...categories.first},

    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              userDataProvider.getPreferredCategoryIcon(),
              color: const Color(0xFF6C63FF),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Recomendado para Você',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3, end: 0),

        const SizedBox(height: 16),

        Hero(
              tag: 'recommended_${preferredCategory['title']}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF9644FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              preferredCategory['icon'] as IconData,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preferredCategory['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Baseado em suas preferências',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        preferredCategory['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.go(
                            '/category-music-list',
                            extra: {
                              'categoryName':
                                  preferredCategory['title'] as String,
                              'audios':
                                  preferredCategory['audios']
                                      as List<AudioModel>,
                              'heroTag':
                                  'recommended_${preferredCategory['title']}',
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Explorar Agora',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms)
            .slideY(begin: 0.3, end: 0)
            .scale(curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildSubscriptionBanner() {
    return GestureDetector(
      onTap: () {
        context.go('/paywall');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B73FF), Color(0xFF9644FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B73FF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Desbloqueie o Premium!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acesso ilimitado, sem anúncios e downloads offline',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
    int index,
    bool isPreferred,
  ) {
    return Hero(
      tag: 'category_${category['title']}_$index',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color:
                isPreferred
                    ? const Color(0xFF6C63FF).withOpacity(0.1)
                    : const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(16),
            border:
                isPreferred
                    ? Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.5),
                      width: 1,
                    )
                    : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isPreferred
                        ? const Color(0xFF6C63FF).withOpacity(0.2)
                        : const Color(0xFF3A3A4E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category['icon'] as IconData,
                color: isPreferred ? const Color(0xFF6C63FF) : Colors.white,
                size: 24,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    category['title'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                          isPreferred ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
                if (isPreferred) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sua Preferência',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().scale(curve: Curves.elasticOut),
                ],
              ],
            ),
            subtitle: Text(
              category['subtitle'] as String,
              style: TextStyle(
                color:
                    isPreferred ? Colors.white.withOpacity(0.8) : Colors.grey,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isPreferred ? const Color(0xFF6C63FF) : Colors.grey,
            ),
            onTap: () {
              context.go(
                '/category-music-list',
                extra: {
                  'categoryName': category['title'] as String,
                  'audios': category['audios'] as List<AudioModel>,
                  'heroTag': 'category_${category['title']}_$index',
                },
              );
            },
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.3, end: 0);
  }

  Widget _buildPopularGrid(List<Map<String, dynamic>> popularItems) {
    return Row(
      children:
          popularItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Expanded(
              child: Container(
                    margin: EdgeInsets.only(
                      right: index < popularItems.length - 1 ? 12 : 0,
                    ),
                    height: 160,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // Navegar para o player ou lista específica
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['subtitle'] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate(delay: (700 + index * 100).ms)
                  .fadeIn()
                  .slideY(begin: 0.3, end: 0),
            );
          }).toList(),
    );
  }

  List<Map<String, Object>> _getOrderedCategories(String? preferredCategory) {
    final allCategories = [
      {
        'title': 'Natureza',
        'subtitle': 'Sons da natureza, chuva, mar e vento',
        'icon': Icons.nature,
        'audios': [
          AudioModel(
            id: '3',
            title: 'Tranquil Pond',
            url: 'https://example.com/audio1.mp3',
            category: 'Natureza',
            duration: const Duration(minutes: 10),
            isPremium: false,
          ),
          AudioModel(
            id: '4',
            title: 'Ocean Waves',
            url: 'https://example.com/ocean.mp3',
            category: 'Natureza',
            duration: const Duration(minutes: 15),
            isPremium: true,
          ),
        ],
      },
      {
        'title': 'Binaural',
        'subtitle': 'Batidas binaurais para foco e relaxamento',
        'icon': Icons.graphic_eq,
        'audios': [
          AudioModel(
            id: '1',
            title: 'Binaural Beats Delta',
            url:
                'assets/music/bineural/binaural-beats_delta_440_440-5hz-48565.mp3',
            category: 'Binaural',
            duration: const Duration(minutes: 5),
            isPremium: false,
          ),
          AudioModel(
            id: '2',
            title: 'Alpha Waves Focus',
            url: 'https://example.com/alpha.mp3',
            category: 'Binaural',
            duration: const Duration(minutes: 8),
            isPremium: true,
          ),
        ],
      },
      {
        'title': 'Instrumental',
        'subtitle': 'Música instrumental relaxante',
        'icon': Icons.music_note,
        'audios': [
          AudioModel(
            id: '13',
            title: 'Piano Relaxante',
            url: 'https://example.com/piano.mp3',
            category: 'Instrumental',
            duration: const Duration(minutes: 12),
            isPremium: false,
          ),
          AudioModel(
            id: '14',
            title: 'Violino Suave',
            url: 'https://example.com/violin.mp3',
            category: 'Instrumental',
            duration: const Duration(minutes: 8),
            isPremium: true,
          ),
        ],
      },
      {
        'title': 'Meditação',
        'subtitle': 'Meditações guiadas e mindfulness',
        'icon': Icons.self_improvement,
        'audios': [
          AudioModel(
            id: '7',
            title: 'Body Scan',
            url: 'https://example.com/audio2.mp3',
            category: 'Meditação',
            duration: const Duration(minutes: 10),
            isPremium: true,
          ),
          AudioModel(
            id: '8',
            title: 'Breathing Exercise',
            url: 'https://example.com/breathing.mp3',
            category: 'Meditação',
            duration: const Duration(minutes: 5),
            isPremium: false,
          ),
        ],
      },
      {
        'title': 'Relaxamento',
        'subtitle': 'Sons e músicas para relaxamento profundo',
        'icon': Icons.spa,
        'audios': [
          AudioModel(
            id: '15',
            title: 'Relaxamento Profundo',
            url: 'https://example.com/deep_relax.mp3',
            category: 'Relaxamento',
            duration: const Duration(minutes: 20),
            isPremium: false,
          ),
          AudioModel(
            id: '16',
            title: 'Spa Sounds',
            url: 'https://example.com/spa.mp3',
            category: 'Relaxamento',
            duration: const Duration(minutes: 15),
            isPremium: true,
          ),
        ],
      },
      {
        'title': 'White Noise',
        'subtitle': 'Ruído branco, rosa e marrom',
        'icon': Icons.blur_on,
        'audios': [
          AudioModel(
            id: '5',
            title: 'White Noise',
            url: 'https://example.com/white_noise.mp3',
            category: 'White Noise',
            duration: const Duration(minutes: 30),
            isPremium: false,
          ),
          AudioModel(
            id: '6',
            title: 'Pink Noise',
            url: 'https://example.com/pink_noise.mp3',
            category: 'White Noise',
            duration: const Duration(minutes: 30),
            isPremium: true,
          ),
        ],
      },
      {
        'title': 'Sleep',
        'subtitle': 'Mixes para sono profundo',
        'icon': Icons.nightlight_round,
        'audios': [
          AudioModel(
            id: '9',
            title: 'Deep Sleep Mix',
            url: 'https://example.com/sleep.mp3',
            category: 'Sleep',
            duration: const Duration(hours: 1),
            isPremium: true,
          ),
          AudioModel(
            id: '10',
            title: 'Lullaby',
            url: 'https://example.com/lullaby.mp3',
            category: 'Sleep',
            duration: const Duration(minutes: 20),
            isPremium: false,
          ),
        ],
      },
    ];

    // Se há uma categoria preferida, colocá-la no início
    if (preferredCategory != null) {
      final preferredIndex = allCategories.indexWhere(
        (cat) => cat['title'] == preferredCategory,
      );

      if (preferredIndex != -1) {
        final preferred = allCategories.removeAt(preferredIndex);
        allCategories.insert(0, preferred);
      }
    }

    return allCategories;
  }

  List<Map<String, dynamic>> _getPopularItems() {
    return [
      {
        'title': 'Tranquil Pond',
        'subtitle': 'Nature Mix',
        'color': const Color(0xFF4A6741),
        'audio': AudioModel(
          id: '11',
          title: 'Tranquil Pond',
          url: 'https://example.com/tranquil_pond.mp3',
          category: 'Nature Mix',
          duration: const Duration(minutes: 12),
          isPremium: false,
        ),
      },
      {
        'title': 'Serenity',
        'subtitle': 'Sleep Mix',
        'color': const Color(0xFF4A4A8A),
        'audio': AudioModel(
          id: '12',
          title: 'Serenity',
          url: 'https://example.com/serenity.mp3',
          category: 'Sleep Mix',
          duration: const Duration(minutes: 25),
          isPremium: true,
        ),
      },
    ];
  }
}

