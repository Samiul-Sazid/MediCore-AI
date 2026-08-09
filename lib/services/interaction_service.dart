import '../models/medication.dart';
import 'api_client.dart';

class InteractionCheckResult {
  final String severity; // 'high' | 'medium' | 'low' | 'allergy' | 'critical'
  final String title;
  final String description;
  final String sourceDrug;
  final String targetDrug;
  final String source;

  InteractionCheckResult({
    required this.severity,
    required this.title,
    required this.description,
    required this.sourceDrug,
    required this.targetDrug,
    this.source = '',
  });
}

/// Drug interaction service — uses 3-layer backend check:
/// Layer 1: Local SQLite DB (110+ rules, instant)
/// Layer 2: OpenFDA API (FDA-verified adverse event data)
/// Layer 3: AI analysis (plain-language safety summary)
///
/// Falls back to a built-in local database if backend is unreachable.
class InteractionService {
  final ApiClient _api = ApiClient();

  // Built-in fallback database for offline use
  static final List<Map<String, String>> _localFallbackInteractions = [
    {'drug1': 'aspirin', 'drug2': 'warfar', 'severity': 'high', 'title': 'Severe Bleeding Risk', 'desc': 'Combined use of Aspirin and Warfarin significantly increases the risk of serious major internal hemorrhaging.'},
    {'drug1': 'aspirin', 'drug2': 'ibuprofen', 'severity': 'medium', 'title': 'Gastrointestinal Ulcer Risk & Antihypertensive Interference', 'desc': 'Ibuprofen may decrease the cardioprotective effects of low-dose aspirin and increases stomach lining irritation.'},
    {'drug1': 'lisinopril', 'drug2': 'spironolactone', 'severity': 'high', 'title': 'Hyperkalemia Risk', 'desc': 'Combining Lisinopril with potassium-sparing diuretics like Spironolactone can cause dangerously elevated potassium levels.'},
    {'drug1': 'lisinopril', 'drug2': 'ibuprofen', 'severity': 'medium', 'title': 'Reduced Kidney Function & Blood Pressure Control', 'desc': 'NSAIDs like Ibuprofen reduce the blood-pressure lowering effectiveness of Lisinopril and stress kidney filtration.'},
    {'drug1': 'metformin', 'drug2': 'prednisone', 'severity': 'medium', 'title': 'Elevated Blood Glucose', 'desc': 'Corticosteroids like Prednisone counteract Metformin by raising blood glucose levels.'},
    {'drug1': 'amiodarone', 'drug2': 'warfar', 'severity': 'high', 'title': 'Enhanced Anticoagulation Effect', 'desc': 'Amiodarone dramatically increases Warfarin blood concentration, creating extreme bleeding hazard.'},
    {'drug1': 'atorvastatin', 'drug2': 'clarithromycin', 'severity': 'high', 'title': 'Rhabdomyolysis Risk', 'desc': 'Clarithromycin inhibits statin metabolism, increasing risk of muscle breakdown and acute kidney injury.'},
    {'drug1': 'sildenafil', 'drug2': 'nitroglycerin', 'severity': 'high', 'title': 'Potentially Fatal Hypotension', 'desc': 'CO-administration of Sildenafil and Nitrates causes severe, refractory drops in blood pressure.'},
    {'drug1': 'sertraline', 'drug2': 'tramadol', 'severity': 'high', 'title': 'Serotonin Syndrome Risk', 'desc': 'Both increase serotonin levels, combined use can cause life-threatening serotonin syndrome.'},
    {'drug1': 'omeprazole', 'drug2': 'clopidogrel', 'severity': 'high', 'title': 'Reduced Antiplatelet Effect', 'desc': 'Omeprazole inhibits CYP2C19 required to activate Clopidogrel, reducing its cardioprotective effect.'},
    {'drug1': 'fluoxetine', 'drug2': 'tramadol', 'severity': 'high', 'title': 'Serotonin Syndrome Risk', 'desc': 'Dual serotonergic activity increases risk of life-threatening serotonin syndrome.'},
    {'drug1': 'warfar', 'drug2': 'fluconazole', 'severity': 'high', 'title': 'Dramatically Elevated INR', 'desc': 'Fluconazole is a potent CYP2C9 inhibitor, significantly increasing Warfarin plasma concentration.'},
    {'drug1': 'digoxin', 'drug2': 'amiodarone', 'severity': 'high', 'title': 'Digoxin Toxicity', 'desc': 'Amiodarone increases Digoxin levels by 70-100% through reduced clearance.'},
    {'drug1': 'lithium', 'drug2': 'ibuprofen', 'severity': 'high', 'title': 'Lithium Toxicity', 'desc': 'NSAIDs reduce renal lithium clearance by 12-25%, causing dangerous accumulation.'},
    {'drug1': 'benzodiazepines', 'drug2': 'opioids', 'severity': 'high', 'title': 'Fatal Respiratory Depression', 'desc': 'Both cause profound CNS and respiratory depression. FDA BLACK BOX WARNING.'},
  ];

  /// Full 3-layer interaction check via backend API.
  /// Returns comprehensive results from local DB, FDA, and AI.
  Future<Map<String, dynamic>> checkInteractionFull(String drugName) async {
    try {
      final response = await _api.post('/drugs/check-interaction', {
        'drug_name': drugName,
      });
      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      return {
        'drug': drugName,
        'allergy_conflicts': [],
        'local_interactions': [],
        'fda_interactions': [],
        'ai_analysis': '',
        'error': 'Could not reach interaction service: $e',
      };
    }
  }

  // Local-only check (used as fallback and for OCR inline checks)
  InteractionCheckResult? checkPair(String drug1, String drug2) {
    final d1 = drug1.trim().toLowerCase();
    final d2 = drug2.trim().toLowerCase();

    for (var rule in _localFallbackInteractions) {
      final r1 = rule['drug1']!;
      final r2 = rule['drug2']!;

      if ((d1.contains(r1) && d2.contains(r2)) || (d1.contains(r2) && d2.contains(r1))) {
        return InteractionCheckResult(
          severity: rule['severity']!,
          title: rule['title']!,
          description: rule['desc']!,
          sourceDrug: drug1,
          targetDrug: drug2,
          source: 'Local DB (offline)',
        );
      }
    }
    return null;
  }

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
          source: 'Patient Profile',
        );
      }
    }
    return null;
  }

  /// Local-only evaluation for inline use (OCR, quick checks).
  /// For full 3-layer checks, use checkInteractionFull().
  List<InteractionCheckResult> evaluateNewMedication({
    required String newDrugName,
    required List<Medication> activeMeds,
    required List<String> drugAllergies,
  }) {
    final List<InteractionCheckResult> results = [];

    final allergyAlert = checkAllergyConflict(newDrugName, drugAllergies);
    if (allergyAlert != null) {
      results.add(allergyAlert);
    }

    for (var med in activeMeds) {
      final inter = checkPair(newDrugName, med.drugName);
      if (inter != null) {
        results.add(inter);
      }
    }

    return results;
  }
}
