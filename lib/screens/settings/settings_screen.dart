import 'package:flutter/material.dart';
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pdfService = PdfService();

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
                final auth = Provider.of<AuthProvider>(context, listen: false);
                Navigator.pop(context);
                await auth.deleteAccount();
                if (mounted) context.go('/login');
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
            Text('Settings', style: AppTypography.displaySmall),
            const SizedBox(height: 24),

            // Section 1: General (Grouped Card matching user screenshot)
            _buildSectionTitle('General'),
            GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingsGroupTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Push reminders & medication alerts',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                  ),
                  const Divider(height: 1),
                  _buildSettingsGroupTile(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: 'Minimal Light Theme Active',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                  ),
                  const Divider(height: 1),
                  _buildSettingsGroupTile(
                    icon: Icons.language_outlined,
                    title: 'Language & Region',
                    subtitle: 'English (US)',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: AI & Export (Grouped Card matching image)
            _buildSectionTitle('AI & Health Reports'),
            GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingsGroupTile(
                    icon: Icons.psychology_outlined,
                    title: 'AI Health Intelligence',
                    subtitle: 'Connected to MediCore Claude Proxy Service',
                    trailing: const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary),
                  ),
                  const Divider(height: 1),
                  _buildSettingsGroupTile(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Export Medical Summary (PDF)',
                    subtitle: 'Generate branded report for clinical visits',
                    onTap: _exportPdfReport,
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Security & Account (Grouped Card matching image)
            _buildSectionTitle('Security'),
            GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingsGroupTile(
                    icon: Icons.fingerprint_outlined,
                    title: 'Biometrics & Security',
                    subtitle: 'HIPAA compliant encryption active',
                    trailing: Switch(
                      value: true,
                      activeColor: AppColors.primary,
                      onChanged: (_) {},
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingsGroupTile(
                    icon: Icons.person_outline,
                    title: 'Signed in Account',
                    subtitle: authProvider.currentUser?.email ?? 'User',
                    trailing: const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary),
                  ),
                  const Divider(height: 1),
                  _buildSettingsGroupTile(
                    icon: Icons.logout_outlined,
                    title: 'Sign Out Session',
                    onTap: () async {
                      await authProvider.logout();
                      if (mounted) context.go('/login');
                    },
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                  ),
                  const Divider(height: 1),
                  _buildSettingsGroupTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Account & Clear Local Data',
                    titleColor: AppColors.danger,
                    onTap: _confirmDeleteAccount,
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.danger),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: Text(
                'MediCore AI • Version 1.0.0 (Clean Minimalist Theme)',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildIconBadge(IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight, // Pale mint squircle matching image
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color ?? AppColors.primary, size: 22),
    );
  }

  Widget _buildSettingsGroupTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _buildIconBadge(icon, color: titleColor),
      title: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: titleColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))
          : null,
      trailing: trailing,
    );
  }
}
