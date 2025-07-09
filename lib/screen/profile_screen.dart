import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sona/provider/user_data_provider.dart';
import 'package:sona/screen/onboarding_screen.dart';
import 'package:sona/service/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar dados do usuário ao inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserDataProvider>(context, listen: false).loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn().slideX(begin: -0.3, end: 0),
        leading:
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/categories'),
            ).animate().fadeIn(delay: 100.ms).scale(),
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do perfil
                _buildProfileHeader(user, userDataProvider),

                const SizedBox(height: 32),

                // Seção de preferências
                _buildPreferencesSection(userDataProvider),

                const SizedBox(height: 32),

                // Seção de estatísticas
                _buildStatsSection(userDataProvider),

                const SizedBox(height: 32),

                // Seção de configurações
                _buildSettingsSection(userDataProvider),

                const SizedBox(height: 32),

                // Botão de logout
                _buildLogoutButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User? user, UserDataProvider userDataProvider) {
    return Container(
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
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),

          const SizedBox(height: 16),

          // Nome/Email
          Text(
            user?.displayName ?? user?.email?.split('@').first ?? 'Usuário',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 8),

          Text(
            user?.email ?? 'Usuário anônimo',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 16),

          // Status do onboarding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  userDataProvider.hasCompletedOnboarding
                      ? Icons.check_circle
                      : Icons.help_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  userDataProvider.hasCompletedOnboarding
                      ? 'Perfil Personalizado'
                      : 'Complete seu perfil',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms).scale(),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildPreferencesSection(UserDataProvider userDataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suas Preferências',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3, end: 0),

        const SizedBox(height: 16),

        if (userDataProvider.hasCompletedOnboarding) ...[
          _buildPreferenceCard(
            'Objetivo Principal',
            userDataProvider.onboardingData?.objetivo ?? 'Não definido',
            Icons.flag,
            () => _editPreferences(),
          ),

          _buildPreferenceCard(
            'Estado Emocional',
            userDataProvider.onboardingData?.humor ?? 'Não definido',
            Icons.mood,
            () => _editPreferences(),
          ),

          _buildPreferenceCard(
            'Estilo Preferido',
            userDataProvider.onboardingData?.estilo ?? 'Não definido',
            Icons.music_note,
            () => _editPreferences(),
          ),

          _buildPreferenceCard(
            'Horário Preferido',
            userDataProvider.onboardingData?.horario ?? 'Não definido',
            Icons.schedule,
            () => _editPreferences(),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Color(0xFF6C63FF),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Complete seu perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Responda algumas perguntas para personalizar sua experiência',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _startOnboarding(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Começar Personalização',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),
        ],
      ],
    );
  }

  Widget _buildPreferenceCard(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        trailing: const Icon(Icons.edit, color: Color(0xFF6C63FF), size: 20),
        onTap: onTap,
      ),
    ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildStatsSection(UserDataProvider userDataProvider) {
    final stats = userDataProvider.getUserStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3, end: 0),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Favoritos',
                '${stats['favoritesCount']}',
                Icons.favorite,
                const Color(0xFFE91E63),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Categoria Preferida',
                stats['preferredCategory'] ?? 'Nenhuma',
                Icons.category,
                const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms).scale();
  }

  Widget _buildSettingsSection(UserDataProvider userDataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configurações',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.3, end: 0),

        const SizedBox(height: 16),

        _buildSettingItem(
          'Editar Preferências',
          'Alterar suas respostas do questionário inicial',
          Icons.edit_note,
          () => _editPreferences(),
          enabled: userDataProvider.hasCompletedOnboarding,
        ),

        _buildSettingItem(
          'Limpar Dados',
          'Remover todas as preferências salvas',
          Icons.delete_outline,
          () => _showClearDataDialog(userDataProvider),
          enabled: userDataProvider.hasCompletedOnboarding,
          isDestructive: true,
        ),

        _buildSettingItem(
          'Sobre o App',
          'Informações sobre o MindWave',
          Icons.info_outline,
          () => _showAboutDialog(),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool enabled = true,
    bool isDestructive = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDestructive ? Colors.red : const Color(0xFF6C63FF))
                .withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFF6C63FF),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color:
                enabled
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white.withOpacity(0.3),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color:
              enabled
                  ? Colors.white.withOpacity(0.7)
                  : Colors.white.withOpacity(0.3),
        ),
        onTap: enabled ? onTap : null,
      ),
    ).animate().fadeIn(delay: 1100.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLogoutDialog(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text(
                'Sair da Conta',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3, end: 0);
  }

  void _startOnboarding() {
    context.go('/onboarding', extra: {'isEditMode': false});
  }

  void _editPreferences() {
    context.go('/onboarding', extra: {'isEditMode': true});
  }

  void _showClearDataDialog(UserDataProvider userDataProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A3E),
            title: const Text(
              'Limpar Dados',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Tem certeza que deseja remover todas as suas preferências? Esta ação não pode ser desfeita.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFF6C63FF)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await userDataProvider.clearOnboardingData();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados removidos com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  'Confirmar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A3E),
            title: const Text(
              'Sobre o MindWave',
              style: TextStyle(color: Colors.white),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MindWave é um aplicativo de relaxamento e foco que oferece sons da natureza, meditações guiadas e batidas binaurais para melhorar seu bem-estar.',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 16),
                Text(
                  'Versão: 1.0.0',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: Color(0xFF6C63FF)),
                ),
              ),
            ],
          ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A3E),
            title: const Text(
              'Sair da Conta',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Tem certeza que deseja sair da sua conta?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFF6C63FF)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await AuthService().signOut();
                  Navigator.of(context).pop();
                  context.go('/login');
                },
                child: const Text('Sair', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
