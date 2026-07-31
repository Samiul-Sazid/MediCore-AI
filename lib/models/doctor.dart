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

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.subSpecialty = '',
    required this.hospital,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.city,
    required this.photoUrl,
    this.availableDays = const ['Mon', 'Wed', 'Fri'],
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
    };
  }

  factory Doctor.fromMap(Map<dynamic, dynamic> map) {
    return Doctor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      subSpecialty: map['subSpecialty'] ?? '',
      hospital: map['hospital'] ?? '',
      experienceYears: map['experienceYears'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      distanceKm: (map['distanceKm'] ?? 0.0).toDouble(),
      city: map['city'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      availableDays: List<String>.from(map['availableDays'] ?? ['Mon', 'Wed', 'Fri']),
    );
  }
}
