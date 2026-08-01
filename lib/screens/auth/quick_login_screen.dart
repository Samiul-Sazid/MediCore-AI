import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/user_account.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class QuickLoginScreen extends StatefulWidget {
  const QuickLoginScreen({super.key});

  @override
  State<QuickLoginScreen> createState() => _QuickLoginScreenState();
}

class _QuickLoginScreenState extends State<QuickLoginScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _showPasswordModal(UserAccount account) {
    _passwordController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AvatarWidget(name: account.fullName, email: account.email, size: 64),
                  const SizedBox(height: 12),
                  Text(account.fullName, style: AppTypography.titleLarge),
                  Text(account.email, style: AppTypography.bodySmall),
                  const SizedBox(height: 20),

                  if (authProvider.errorMessage != null) ...[
                    Text(
                      authProvider.errorMessage!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  GradientButton(
                    text: 'Unlock Health Portal',
                    width: double.infinity,
                    isLoading: authProvider.isLoading,
                    onPressed: () async {
                      final success = await authProvider.quickLogin(
                        userId: account.id,
                        password: _passwordController.text,
                      );
                      if (success && context.mounted) {
                        Navigator.pop(context);
                        context.go('/dashboard');
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final accounts = authProvider.savedAccounts;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E1A), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: AppColors.primaryGradient),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.black, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('Quick Account Switcher', style: AppTypography.displaySmall),
                  const SizedBox(height: 6),
                  Text('Tap your avatar profile to sign in instantly', style: AppTypography.bodyMedium),
                  const SizedBox(height: 28),

                  if (accounts.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.no_accounts_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No Saved Accounts Found', style: AppTypography.titleMedium),
                          const SizedBox(height: 16),
                          GradientButton(
                            text: 'Sign In to Account',
                            onPressed: () => context.go('/login'),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return GlassCard(
                          onTap: () => _showPasswordModal(account),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AvatarWidget(name: account.fullName, email: account.email, size: 52),
                              const SizedBox(height: 10),
                              Text(
                                account.fullName,
                                style: AppTypography.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                account.email,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text('Sign In with another email', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                      ),
                      Text(' • ', style: AppTypography.bodyMedium),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text('Register New Account', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
