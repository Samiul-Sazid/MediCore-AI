import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/history_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/claude_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _claudeService = ClaudeService();
  final _pdfService = PdfService();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = _claudeService.getApiKey() ?? '';
  }

  void _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      await Provider.of<ChatProvider>(context, listen: false).saveApiKey(key);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anthropic API key saved successfully! Claude AI features are live.')),
        );
      }
    }
  }

  void _clearApiKey() async {
    await Provider.of<ChatProvider>(context, listen: false).clearApiKey();
    _apiKeyController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key cleared.')),
      );
    }
  }

  void _exportPdfReport() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final medProvider = Provider.of<MedicationProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    final user = authProvider.currentUser;
    final profile = profileProvider.profile;

    if (user != null && profile != null) {
      await _pdfService.shareOrPrintReport(
        account: user,
        profile: profile,
        activeMeds: medProvider.activeMedications,
        recentEvents: historyProvider.events,
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete Account & Data?'),
          content: const Text(
            'This action is irreversible. All local health records, prescriptions, chat sessions, and document vaults will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                Navigator.pop(context);
                await Provider.of<AuthProvider>(context, listen: false).deleteAccount();
                if (context.mounted) context.go('/login');
              },
              child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Settings & Security', style: AppTypography.displaySmall),
            Text('Configure AI integrations, export health reports, and manage privacy', style: AppTypography.bodySmall),
            const SizedBox(height: 24),

            // Anthropic API Key Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Text('Anthropic Claude API Integration', style: AppTypography.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your personal Anthropic API key to enable live Claude 3.5 Sonnet medical AI advice.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'API Key (sk-ant-...)',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GradientButton(
                        text: 'Save Key',
                        icon: Icons.check,
                        onPressed: _saveApiKey,
                      ),
                      const SizedBox(width: 12),
                      if (chatProvider.hasApiKey)
                        OutlinedButton(
                          onPressed: _clearApiKey,
                          child: const Text('Remove Key', style: TextStyle(color: AppColors.danger)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // PDF Export Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: AppColors.secondary, size: 28),
                      const SizedBox(width: 12),
                      Text('PDF Health Summary Export', style: AppTypography.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate a branded PDF health report containing active prescriptions, allergies, biometrics, and timeline history for your physician.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    text: 'Export & Print Health Report PDF',
                    icon: Icons.print,
                    gradient: AppColors.accentGradient,
                    onPressed: _exportPdfReport,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account & Session Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account & Privacy', style: AppTypography.titleLarge),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.warning),
                    title: const Text('Sign Out'),
                    subtitle: Text('Logged in as ${authProvider.currentUser?.email}'),
                    onTap: () async {
                      await authProvider.logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppColors.danger),
                    title: const Text('Delete Account & Clear All Data', style: TextStyle(color: AppColors.danger)),
                    subtitle: const Text('Purge all encrypted Hive data boxes permanently'),
                    onTap: _confirmDeleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: Text(
                'MediCore AI • Version 1.0.0 (Flutter)',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
