import 'package:flutter/foundation.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService = DoctorService();

  List<Doctor> _matchedDoctors = [];
  List<String> _selectedSymptoms = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Appointment state
  List<Map<String, dynamic>> _appointments = [];
  String? _bookedDoctorName;

  List<Doctor> get doctors => _matchedDoctors;
  List<String> get selectedSymptoms => _selectedSymptoms;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get appointments => _appointments;
  String? get bookedDoctorName => _bookedDoctorName;

  /// Load doctors from backend.
  Future<void> loadDoctors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _matchedDoctors = await _doctorService.fetchDoctors(
        query: _searchQuery,
        symptoms: _selectedSymptoms,
      );
    } catch (e) {
      _errorMessage = 'Could not load doctors. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search({String? query, List<String>? symptoms}) async {
    if (query != null) _searchQuery = query;
    if (symptoms != null) _selectedSymptoms = symptoms;
    await loadDoctors();
  }

  void addSymptom(String symptom) {
    if (!_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.add(symptom);
      loadDoctors();
    }
  }

  void removeSymptom(String symptom) {
    _selectedSymptoms.remove(symptom);
    loadDoctors();
  }

  void clearSymptoms() {
    _selectedSymptoms.clear();
    loadDoctors();
  }

  /// Fetch available slots for a doctor.
  Future<List<Map<String, dynamic>>> getSlots(String doctorId, {String? date, String? day}) async {
    return _doctorService.fetchSlots(doctorId, date: date, day: day);
  }

  /// Book an appointment with a doctor.
  Future<bool> bookAppointment({
    required Doctor doctor,
    required String appointmentDate,
    required String startTime,
    String endTime = '',
    String reason = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _doctorService.bookAppointment(
        doctorId: doctor.id,
        appointmentDate: appointmentDate,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      _bookedDoctorName = doctor.name;
      await loadAppointments();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user's appointments from backend.
  Future<void> loadAppointments() async {
    try {
      _appointments = await _doctorService.fetchAppointments();
    } catch (e) {
      if (kDebugMode) print('Failed to load appointments: $e');
    }
    notifyListeners();
  }

  /// Cancel an appointment.
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await _doctorService.cancelAppointment(appointmentId);
      await loadAppointments();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel appointment.';
      notifyListeners();
      return false;
    }
  }

  void clearBookedNotification() {
    _bookedDoctorName = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
