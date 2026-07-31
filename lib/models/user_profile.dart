class UserProfile {
  final String userId;
  final String gender;
  final String bloodType;
  final double weightKg;
  final double heightCm;
  final String phone;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;
  final List<String> conditions;
  final List<String> drugAllergies;
  final List<String> foodAllergies;
  final List<String> sensitivities;
  final List<String> familyHistory;
  final String insuranceProvider;
  final String policyNumber;
  final String pcpName;
  final String pcpPhone;

  UserProfile({
    required this.userId,
    this.gender = 'Unspecified',
    this.bloodType = 'Unknown',
    this.weightKg = 70.0,
    this.heightCm = 175.0,
    this.phone = '',
    this.address = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelation = '',
    this.conditions = const [],
    this.drugAllergies = const [],
    this.foodAllergies = const [],
    this.sensitivities = const [],
    this.familyHistory = const [],
    this.insuranceProvider = '',
    this.policyNumber = '',
    this.pcpName = '',
    this.pcpPhone = '',
  });

  double get bmi => (heightCm > 0) ? (weightKg / ((heightCm / 100) * (heightCm / 100))) : 0.0;
  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal weight';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gender': gender,
      'bloodType': bloodType,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'phone': phone,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelation': emergencyContactRelation,
      'conditions': conditions,
      'drugAllergies': drugAllergies,
      'foodAllergies': foodAllergies,
      'sensitivities': sensitivities,
      'familyHistory': familyHistory,
      'insuranceProvider': insuranceProvider,
      'policyNumber': policyNumber,
      'pcpName': pcpName,
      'pcpPhone': pcpPhone,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      gender: map['gender'] ?? 'Unspecified',
      bloodType: map['bloodType'] ?? 'Unknown',
      weightKg: (map['weightKg'] ?? 70.0).toDouble(),
      heightCm: (map['heightCm'] ?? 175.0).toDouble(),
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] ?? '',
      emergencyContactRelation: map['emergencyContactRelation'] ?? '',
      conditions: List<String>.from(map['conditions'] ?? []),
      drugAllergies: List<String>.from(map['drugAllergies'] ?? []),
      foodAllergies: List<String>.from(map['foodAllergies'] ?? []),
      sensitivities: List<String>.from(map['sensitivities'] ?? []),
      familyHistory: List<String>.from(map['familyHistory'] ?? []),
      insuranceProvider: map['insuranceProvider'] ?? '',
      policyNumber: map['policyNumber'] ?? '',
      pcpName: map['pcpName'] ?? '',
      pcpPhone: map['pcpPhone'] ?? '',
    );
  }
}
