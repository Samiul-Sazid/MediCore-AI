import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/password_strength_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _acceptedTerms = true;

  void _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 5, 15),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  void _register() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Privacy Policy & Terms of Service.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      dob: _selectedDob,
    );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: AppColors.primaryGradient),
                        ),
                        child: const Icon(Icons.local_hospital_rounded, color: Colors.black, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Text('MediCore AI', style: AppTypography.displayMedium),
                    ],
                  ),
                  const SizedBox(height: 24),

                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Health Account', style: AppTypography.displaySmall.copyWith(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text('Setup your encrypted medical profile & dashboard', style: AppTypography.bodyMedium),
                        const SizedBox(height: 20),

                        if (authProvider.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.danger),
                            ),
                            child: Text(
                              authProvider.errorMessage!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(labelText: 'First Name'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(labelText: 'Last Name'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: 14),

                        InkWell(
                          onTap: _pickDob,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              prefixIcon: Icon(Icons.calendar_month, color: AppColors.textMuted),
                            ),
                            child: Text(
                              _selectedDob != null ? dateFormat.format(_selectedDob!) : 'Select Date of Birth',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _selectedDob != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        PasswordStrengthBar(password: _passwordController.text),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              activeColor: AppColors.primary,
                              checkColor: Colors.black,
                              onChanged: (val) => setState(() => _acceptedTerms = val ?? true),
                            ),
                            Expanded(
                              child: Text(
                                'I accept HIPAA compliance, Terms of Service & Privacy Policy',
                                style: AppTypography.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        GradientButton(
                          text: 'Create Account & Access Portal',
                          onPressed: _register,
                          isLoading: authProvider.isLoading,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already registered? ', style: AppTypography.bodyMedium),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text('Sign In', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
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
