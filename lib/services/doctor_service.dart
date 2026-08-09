import 'package:flutter/foundation.dart';
import '../models/doctor.dart';
import 'api_client.dart';

class DoctorService {
  final ApiClient _api = ApiClient();

  // Symptom-to-specialty mapping for intelligent doctor matching
  static const Map<String, List<String>> _symptomSpecialtyMap = {
    'chest pain': ['Cardiology', 'General Practice'],
    'palpitations': ['Cardiology'],
    'high blood pressure': ['Cardiology', 'Endocrinology'],
    'headache': ['Neurology', 'General Practice'],
    'dizziness': ['Neurology', 'Cardiology'],
    'numbness': ['Neurology'],
    'joint pain': ['Orthopedics', 'Rheumatology'],
    'back pain': ['Orthopedics'],
    'arthritis': ['Rheumatology'],
    'rash': ['Dermatology'],
    'skin lesion': ['Dermatology'],
    'acne': ['Dermatology'],
    'fatigue': ['Endocrinology', 'General Practice'],
    'sugar level': ['Endocrinology'],
    'diabetes': ['Endocrinology'],
    'thyroid': ['Endocrinology'],
    'fever': ['General Practice'],
    'cough': ['Pulmonology', 'General Practice'],
    'breathing': ['Pulmonology', 'Cardiology'],
    'asthma': ['Pulmonology'],
    'anxiety': ['Psychiatry', 'General Practice'],
    'depression': ['Psychiatry'],
    'stomach': ['Gastroenterology'],
    'digestion': ['Gastroenterology'],
    'vision': ['Ophthalmology'],
    'eye': ['Ophthalmology'],
    'ear': ['ENT'],
    'hearing': ['ENT'],
    'sinus': ['ENT'],
    'kidney': ['Nephrology', 'Urology'],
    'urinary': ['Urology'],
    'child': ['Pediatrics'],
    'cancer': ['Oncology'],
  };

  /// Fetch doctors from the backend API.
  Future<List<Doctor>> fetchDoctors({String query = '', List<String> symptoms = const []}) async {
    try {
      // Build specialty filter from symptoms
      String specialtyFilter = '';
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
          specialtyFilter = targetSpecialties.first;
        }
      }

      String endpoint = '/doctors/?';
      if (query.isNotEmpty) endpoint += 'query=${Uri.encodeComponent(query)}&';
      if (specialtyFilter.isNotEmpty) endpoint += 'specialty=${Uri.encodeComponent(specialtyFilter)}&';

      final data = await _api.get(endpoint);
      if (data != null && data is List) {
        return data.map((d) => Doctor(
          id: d['id'].toString(),
          name: d['name'] ?? '',
          specialty: d['specialty'] ?? '',
          subSpecialty: d['sub_specialty'] ?? '',
          hospital: d['hospital'] ?? '',
          experienceYears: d['experience_years'] ?? 0,
          rating: (d['rating'] ?? 4.5).toDouble(),
          reviewCount: d['review_count'] ?? 0,
          distanceKm: 0.0,
          city: d['city'] ?? '',
          photoUrl: d['photo_url'] ?? '',
          availableDays: List<String>.from(d['available_days'] ?? []),
          qualifications: d['qualifications'] ?? '',
          consultationFee: (d['consultation_fee'] ?? 0.0).toDouble(),
        )).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Failed to fetch doctors from API: $e');
    }
    return [];
  }

  /// Fetch available time slots for a doctor on a specific date.
  Future<List<Map<String, dynamic>>> fetchSlots(String doctorId, {String? date, String? day}) async {
    try {
      String endpoint = '/doctors/$doctorId/slots?';
      if (date != null) endpoint += 'date=${Uri.encodeComponent(date)}&';
      if (day != null) endpoint += 'day=${Uri.encodeComponent(day)}&';

      final data = await _api.get(endpoint);
      if (data != null && data is List) {
        return data.map((s) => Map<String, dynamic>.from(s)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Failed to fetch slots: $e');
    }
    return [];
  }

  /// Book an appointment with a doctor.
  Future<Map<String, dynamic>?> bookAppointment({
    required String doctorId,
    required String appointmentDate,
    required String startTime,
    String endTime = '',
    String reason = '',
  }) async {
    try {
      final response = await _api.post('/doctors/book', {
        'doctor_id': int.parse(doctorId),
        'appointment_date': appointmentDate,
        'start_time': startTime,
        'end_time': endTime,
        'reason': reason,
      });
      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch user's appointments.
  Future<List<Map<String, dynamic>>> fetchAppointments({String? status}) async {
    try {
      String endpoint = '/doctors/appointments';
      if (status != null) endpoint += '?status=$status';

      final data = await _api.get(endpoint);
      if (data != null && data is List) {
        return data.map((a) => Map<String, dynamic>.from(a)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Failed to fetch appointments: $e');
    }
    return [];
  }

  /// Cancel an appointment.
  Future<void> cancelAppointment(String appointmentId) async {
    await _api.put('/doctors/appointments/$appointmentId/cancel', {});
  }

  /// Search doctors using the symptom-specialty mapping.
  List<Doctor> filterBySymptoms(List<Doctor> doctors, List<String> symptoms) {
    if (symptoms.isEmpty) return doctors;

    final Set<String> targetSpecialties = {};
    for (var s in symptoms) {
      final key = s.trim().toLowerCase();
      _symptomSpecialtyMap.forEach((symptomKey, specs) {
        if (key.contains(symptomKey) || symptomKey.contains(key)) {
          targetSpecialties.addAll(specs);
        }
      });
    }

    if (targetSpecialties.isEmpty) return doctors;
    return doctors.where((d) => targetSpecialties.contains(d.specialty)).toList();
  }
}
