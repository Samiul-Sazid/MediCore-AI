class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String subSpecialty;
  final String hospital;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String city;
  final String photoUrl;
  final List<String> availableDays;
  final String qualifications;
  final double consultationFee;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.subSpecialty = '',
    required this.hospital,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    this.distanceKm = 0.0,
    required this.city,
    this.photoUrl = '',
    this.availableDays = const ['Mon', 'Wed', 'Fri'],
    this.qualifications = '',
    this.consultationFee = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'subSpecialty': subSpecialty,
      'hospital': hospital,
      'experienceYears': experienceYears,
      'rating': rating,
      'reviewCount': reviewCount,
      'distanceKm': distanceKm,
      'city': city,
      'photoUrl': photoUrl,
      'availableDays': availableDays,
      'qualifications': qualifications,
      'consultationFee': consultationFee,
    };
  }

  factory Doctor.fromMap(Map<dynamic, dynamic> map) {
    return Doctor(
      id: (map['id'] ?? '').toString(),
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      subSpecialty: map['subSpecialty'] ?? map['sub_specialty'] ?? '',
      hospital: map['hospital'] ?? '',
      experienceYears: map['experienceYears'] ?? map['experience_years'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? map['review_count'] ?? 0,
      distanceKm: (map['distanceKm'] ?? map['distance_km'] ?? 0.0).toDouble(),
      city: map['city'] ?? '',
      photoUrl: map['photoUrl'] ?? map['photo_url'] ?? '',
      availableDays: List<String>.from(map['availableDays'] ?? map['available_days'] ?? ['Mon', 'Wed', 'Fri']),
      qualifications: map['qualifications'] ?? '',
      consultationFee: (map['consultationFee'] ?? map['consultation_fee'] ?? 0.0).toDouble(),
    );
  }
}
