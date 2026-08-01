import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/search_chip_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _phoneController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _emergencyRelationController;
  late TextEditingController _insuranceProviderController;
  late TextEditingController _policyNumberController;
  late TextEditingController _pcpNameController;
  late TextEditingController _pcpPhoneController;

  String _selectedGender = 'Unspecified';
  String _selectedBloodType = 'O+';
  List<String> _conditions = [];
  List<String> _drugAllergies = [];
  List<String> _foodAllergies = [];

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final profile = Provider.of<ProfileProvider>(context).profile;
      if (profile != null) {
        _phoneController = TextEditingController(text: profile.phone);
        _weightController = TextEditingController(text: profile.weightKg.toString());
        _heightController = TextEditingController(text: profile.heightCm.toString());
        _emergencyNameController = TextEditingController(text: profile.emergencyContactName);
        _emergencyPhoneController = TextEditingController(text: profile.emergencyContactPhone);
        _emergencyRelationController = TextEditingController(text: profile.emergencyContactRelation);
        _insuranceProviderController = TextEditingController(text: profile.insuranceProvider);
        _policyNumberController = TextEditingController(text: profile.policyNumber);
        _pcpNameController = TextEditingController(text: profile.pcpName);
        _pcpPhoneController = TextEditingController(text: profile.pcpPhone);

        _selectedGender = profile.gender;
        _selectedBloodType = profile.bloodType;
        _conditions = List.from(profile.conditions);
        _drugAllergies = List.from(profile.drugAllergies);
        _foodAllergies = List.from(profile.foodAllergies);
        _isInitialized = true;
      }
    }
  }

  void _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      final updated = UserProfile(
        userId: user.id,
        gender: _selectedGender,
        bloodType: _selectedBloodType,
        weightKg: double.tryParse(_weightController.text) ?? 70.0,
        heightCm: double.tryParse(_heightController.text) ?? 175.0,
        phone: _phoneController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
        emergencyContactRelation: _emergencyRelationController.text.trim(),
        conditions: _conditions,
        drugAllergies: _drugAllergies,
        foodAllergies: _foodAllergies,
        insuranceProvider: _insuranceProviderController.text.trim(),
        policyNumber: _policyNumberController.text.trim(),
        pcpName: _pcpNameController.text.trim(),
        pcpPhone: _pcpPhoneController.text.trim(),
      );

      await profileProvider.updateProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    if (user == null || !_isInitialized) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Health Profile', style: AppTypography.displaySmall),
                    Text('Manage your electronic medical records & emergency details', style: AppTypography.bodySmall),
                  ],
                ),
                GradientButton(
                  text: 'Save Changes',
                  icon: Icons.save,
                  onPressed: _saveProfile,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Demographics Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personal & Biometric Data', style: AppTypography.titleLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: ['Male', 'Female', 'Other', 'Unspecified'].contains(_selectedGender) ? _selectedGender : 'Unspecified',
                          decoration: const InputDecoration(labelText: 'Gender'),
                          dropdownColor: AppColors.surface,
                          items: ['Male', 'Female', 'Other', 'Unspecified']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedGender = val ?? 'Unspecified'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'].contains(_selectedBloodType) ? _selectedBloodType : 'O+',
                          decoration: const InputDecoration(labelText: 'Blood Type'),
                          dropdownColor: AppColors.surface,
                          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown']
                              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedBloodType = val ?? 'O+'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Weight (kg)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Height (cm)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Allergies & Conditions Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Documented Allergies & Medical Conditions', style: AppTypography.titleLarge),
                  const SizedBox(height: 16),
                  Text('Drug Allergies (High Severity)', style: AppTypography.titleSmall.copyWith(color: AppColors.danger)),
                  const SizedBox(height: 8),
                  SearchChipField(
                    selectedChips: _drugAllergies,
                    hintText: 'Add drug allergy (e.g. Penicillin)...',
                    suggestions: const ['Penicillin', 'Sulfa Drugs', 'Aspirin', 'Codeine', 'Amoxicillin'],
                    onAdd: (tag) => setState(() => _drugAllergies.add(tag)),
                    onRemove: (tag) => setState(() => _drugAllergies.remove(tag)),
                  ),
                  const SizedBox(height: 20),

                  Text('Medical Conditions', style: AppTypography.titleSmall),
                  const SizedBox(height: 8),
                  SearchChipField(
                    selectedChips: _conditions,
                    hintText: 'Add medical condition (e.g. Hypertension)...',
                    suggestions: const ['Hypertension', 'Type 2 Diabetes', 'Asthma', 'High Cholesterol'],
                    onAdd: (tag) => setState(() => _conditions.add(tag)),
                    onRemove: (tag) => setState(() => _conditions.remove(tag)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Contacts Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency Contact Details', style: AppTypography.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(labelText: 'Contact Person Name'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emergencyPhoneController,
                          decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _emergencyRelationController,
                          decoration: const InputDecoration(labelText: 'Relationship (e.g. Spouse)'),
                        ),
                      ),
                    ],
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
