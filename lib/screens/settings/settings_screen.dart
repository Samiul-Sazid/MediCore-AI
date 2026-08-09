import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/history_provider.dart';
import '../../services/pdf_service.dart';
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
  final _pdfService = PdfService();
  bool _backendConnected = false;
  bool _checkingConnection = true;

  @override
  void initState() {
    super.initState();
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    setState(() => _checkingConnection = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/health'),
      ).timeout(const Duration(seconds: 3));
      _backendConnected = response.statusCode == 200;
    } catch (e) {
      _backendConnected = false;
    }
    if (mounted) setState(() => _checkingConnection = false);
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

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Settings & Security', style: AppTypography.displaySmall),
            Text('Manage your account, export health reports, and view app status', style: AppTypography.bodySmall),
            const SizedBox(height: 24),

            // Backend Connection Status Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Text('Backend Connection', style: AppTypography.titleLarge),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _backendConnected
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _backendConnected ? Icons.check_circle : Icons.warning_amber,
                              color: _backendConnected ? AppColors.success : AppColors.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _checkingConnection
                                  ? 'Checking...'
                                  : _backendConnected
                                      ? 'Connected'
                                      : 'Offline',
                              style: TextStyle(
                                color: _backendConnected ? AppColors.success : AppColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _backendConnected
                        ? 'Backend server is running. AI Advisor, drug interaction checks, and doctor directory are fully functional.'
                        : 'Backend server not detected at http://127.0.0.1:5000. Some features will operate in offline mode with local data only.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AI Advisor, OCR Scanner, and Drug Interaction Engine are powered by the backend server. No API key configuration needed.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
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
                'MediCore AI • Version 1.0.0 (Flutter + Flask)',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
