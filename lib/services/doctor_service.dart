import '../models/doctor.dart';

class DoctorService {
  static final List<Doctor> _doctorDatabase = [
    Doctor(
      id: 'doc-1',
      name: 'Dr. Sarah Lin',
      specialty: 'Cardiology',
      subSpecialty: 'Heart Failure & Arrhythmia',
      hospital: 'St. Jude Heart Institute',
      experienceYears: 16,
      rating: 4.9,
      reviewCount: 142,
      distanceKm: 2.4,
      city: 'Metropolis',
      photoUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=300',
      availableDays: ['Mon', 'Tue', 'Thu'],
    ),
    Doctor(
      id: 'doc-2',
      name: 'Dr. Marcus Vance',
      specialty: 'Neurology',
      subSpecialty: 'Migraine & Memory Disorders',
      hospital: 'University Neurological Center',
      experienceYears: 12,
      rating: 4.8,
      reviewCount: 98,
      distanceKm: 4.1,
      city: 'Metropolis',
      photoUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=300',
      availableDays: ['Wed', 'Thu', 'Fri'],
    ),
    Doctor(
      id: 'doc-3',
      name: 'Dr. Elena Rostova',
      specialty: 'Endocrinology',
      subSpecialty: 'Diabetes & Thyroid Specialist',
      hospital: 'Metropolitan Medical Center',
      experienceYears: 19,
      rating: 4.95,
      reviewCount: 215,
      distanceKm: 1.8,
      city: 'Metropolis',
      photoUrl: 'https://images.unsplash.com/photo-1594824813566-88855ce75341?w=300',
      availableDays: ['Mon', 'Wed', 'Fri'],
    ),
    Doctor(
      id: 'doc-4',
      name: 'Dr. Jonathan Reed',
      specialty: 'Orthopedics',
      subSpecialty: 'Joint Replacement & Sports Injury',
      hospital: 'OrthoCare Surgery Center',
      experienceYears: 14,
      rating: 4.75,
      reviewCount: 84,
      distanceKm: 6.2,
      city: 'Metropolis',
      photoUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=300',
      availableDays: ['Tue', 'Thu', 'Sat'],
    ),
    Doctor(
      id: 'doc-5',
      name: 'Dr. Chloe Bennett',
      specialty: 'Dermatology',
      subSpecialty: 'Clinical Dermatology & Laser Therapy',
      hospital: 'Skin & Laser Wellness Clinic',
      experienceYears: 9,
      rating: 4.85,
      reviewCount: 167,
      distanceKm: 3.5,
      city: 'Metropolis',
      photoUrl: 'https://images.unsplash.com/photo-1527613426441-4da17471b66d?w=300',
      availableDays: ['Mon', 'Tue', 'Wed', 'Fri'],
    ),
    Doctor(
      id: 'doc-6',
      name: 'Dr. Aris Thorne',
      specialty: 'General Practice',
      subSpecialty: 'Preventive Care & Internal Medicine',
      hospital: 'Community Family Care',
      experienceYears: 22,
      rating: 4.9,
      reviewCount: 310,
      distanceKm: 1.2,
      city: 'Metropolis',
      photoUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=300',
      availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    ),
  ];

  static const Map<String, List<String>> _symptomSpecialtyMap = {
    'chest pain': ['Cardiology', 'General Practice'],
    'palpitations': ['Cardiology'],
    'high blood pressure': ['Cardiology', 'Endocrinology'],
    'headache': ['Neurology', 'General Practice'],
    'dizziness': ['Neurology', 'Cardiology'],
    'numbness': ['Neurology'],
    'joint pain': ['Orthopedics'],
    'back pain': ['Orthopedics'],
    'rash': ['Dermatology'],
    'skin lesion': ['Dermatology'],
    'fatigue': ['Endocrinology', 'General Practice'],
    'sugar level': ['Endocrinology'],
    'fever': ['General Practice'],
  };

  List<Doctor> searchDoctors({String query = '', List<String> symptoms = const []}) {
    List<Doctor> list = List.from(_doctorDatabase);

    // Filter by symptoms if provided
    if (symptoms.isNotEmpty) {
      final Set<String> targetSpecialties = {};
      for (var s in symptoms) {
        final key = s.trim().toLowerCase();
        _symptomSpecialtyMap.forEach((symptomKey, specs) {
          if (key.contains(symptomKey) || symptomKey.contains(key)) {
            targetSpecialties.addAll(specs);
          }
        });
      }

      if (targetSpecialties.isNotEmpty) {
        list = list.where((d) => targetSpecialties.contains(d.specialty)).toList();
      }
    }

    // Filter by text query if provided
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((d) =>
        d.name.toLowerCase().contains(q) ||
        d.specialty.toLowerCase().contains(q) ||
        d.hospital.toLowerCase().contains(q) ||
        d.subSpecialty.toLowerCase().contains(q)
      ).toList();
    }

    // Sort by rating descending
    list.sort((a, b) => b.rating.compareTo(a.rating));
    return list;
  }
}
