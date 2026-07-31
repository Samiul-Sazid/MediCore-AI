import 'package:flutter/foundation.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService = DoctorService();

  List<Doctor> _matchedDoctors = [];
  List<String> _selectedSymptoms = [];
  String _searchQuery = '';
  String? _bookedDoctorName;

  List<Doctor> get doctors => _matchedDoctors;
  List<String> get selectedSymptoms => _selectedSymptoms;
  String get searchQuery => _searchQuery;
  String? get bookedDoctorName => _bookedDoctorName;

  DoctorProvider() {
    search();
  }

  void search({String? query, List<String>? symptoms}) {
    if (query != null) _searchQuery = query;
    if (symptoms != null) _selectedSymptoms = symptoms;

    _matchedDoctors = _doctorService.searchDoctors(
      query: _searchQuery,
      symptoms: _selectedSymptoms,
    );
    notifyListeners();
  }

  void addSymptom(String symptom) {
    if (!_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.add(symptom);
      search();
    }
  }

  void removeSymptom(String symptom) {
    _selectedSymptoms.remove(symptom);
    search();
  }

  void clearSymptoms() {
    _selectedSymptoms.clear();
    search();
  }

  void bookAppointment(Doctor doctor) {
    _bookedDoctorName = doctor.name;
    notifyListeners();
  }

  void clearBookedNotification() {
    _bookedDoctorName = null;
    notifyListeners();
  }
}
