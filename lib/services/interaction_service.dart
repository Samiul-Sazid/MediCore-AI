import '../models/medication.dart';

class InteractionCheckResult {
  final String severity; // 'high' | 'medium' | 'low' | 'allergy'
  final String title;
  final String description;
  final String sourceDrug;
  final String targetDrug;

  InteractionCheckResult({
    required this.severity,
    required this.title,
    required this.description,
    required this.sourceDrug,
    required this.targetDrug,
  });
}

class InteractionService {
  // Built-in database of common drug interactions
  static final List<Map<String, String>> _drugInteractions = [
    {
      'drug1': 'aspirin',
      'drug2': 'warfar',
      'severity': 'high',
      'title': 'Severe Bleeding Risk',
      'desc': 'Combined use of Aspirin and Warfarin significantly increases the risk of serious major internal hemorrhaging.',
    },
    {
      'drug1': 'aspirin',
      'drug2': 'ibuprofen',
      'severity': 'medium',
      'title': 'Gastrointestinal Ulcer Risk & Antihypertensive Interference',
      'desc': 'Ibuprofen may decrease the cardioprotective effects of low-dose aspirin and increases stomach lining irritation.',
    },
    {
      'drug1': 'lisinopril',
      'drug2': 'spironolactone',
      'severity': 'high',
      'title': 'Hyperkalemia Risk',
      'desc': 'Combining Lisinopril with potassium-sparing diuretics like Spironolactone can cause dangerously elevated potassium levels.',
    },
    {
      'drug1': 'lisinopril',
      'drug2': 'ibuprofen',
      'severity': 'medium',
      'title': 'Reduced Kidney Function & Blood Pressure Control',
      'desc': 'NSAIDs like Ibuprofen reduce the blood-pressure lowering effectiveness of Lisinopril and stress kidney filtration.',
    },
    {
      'drug1': 'metformin',
      'drug2': 'prednisone',
      'severity': 'medium',
      'title': 'Elevated Blood Glucose',
      'desc': 'Corticosteroids like Prednisone counteract Metformin by raising blood glucose levels.',
    },
    {
      'drug1': 'amiodarone',
      'drug2': 'warfar',
      'severity': 'high',
      'title': 'Enhanced Anticoagulation Effect',
      'desc': 'Amiodarone dramatically increases Warfarin blood concentration, creating extreme bleeding hazard.',
    },
    {
      'drug1': 'atorvastatin',
      'drug2': 'clarithromycin',
      'severity': 'high',
      'title': 'Rhabdomyolysis Risk',
      'desc': 'Clarithromycin inhibits statin metabolism, increasing risk of muscle breakdown and acute kidney injury.',
    },
    {
      'drug1': 'sildenafil',
      'drug2': 'nitroglycerin',
      'severity': 'high',
      'title': 'Potentially Fatal Hypotension',
      'desc': 'CO-administration of Sildenafil and Nitrates causes severe, refractory drops in blood pressure.',
    },
  ];

  // Check single pair of drugs
  InteractionCheckResult? checkPair(String drug1, String drug2) {
    final d1 = drug1.trim().toLowerCase();
    final d2 = drug2.trim().toLowerCase();

    for (var rule in _drugInteractions) {
      final r1 = rule['drug1']!;
      final r2 = rule['drug2']!;

      if ((d1.contains(r1) && d2.contains(r2)) || (d1.contains(r2) && d2.contains(r1))) {
        return InteractionCheckResult(
          severity: rule['severity']!,
          title: rule['title']!,
          description: rule['desc']!,
          sourceDrug: drug1,
          targetDrug: drug2,
        );
      }
    }
    return null;
  }

  // Check drug against list of allergies
  InteractionCheckResult? checkAllergyConflict(String drugName, List<String> drugAllergies) {
    final d = drugName.trim().toLowerCase();
    for (var allergy in drugAllergies) {
      final a = allergy.trim().toLowerCase();
      if (d.contains(a) || a.contains(d)) {
        return InteractionCheckResult(
          severity: 'allergy',
          title: 'DIRECT ALLERGY CONFLICT ⚠',
          description: 'The medication "$drugName" matches your documented allergy to "$allergy". Administration may trigger severe allergic response or anaphylaxis.',
          sourceDrug: drugName,
          targetDrug: allergy,
        );
      }
    }
    return null;
  }

  // Evaluate candidate drug against current active medications and allergies
  List<InteractionCheckResult> evaluateNewMedication({
    required String newDrugName,
    required List<Medication> activeMeds,
    required List<String> drugAllergies,
  }) {
    final List<InteractionCheckResult> results = [];

    // Allergy check first
    final allergyAlert = checkAllergyConflict(newDrugName, drugAllergies);
    if (allergyAlert != null) {
      results.add(allergyAlert);
    }

    // Drug-drug interaction check
    for (var med in activeMeds) {
      final inter = checkPair(newDrugName, med.drugName);
      if (inter != null) {
        results.add(inter);
      }
    }

    return results;
  }
}
