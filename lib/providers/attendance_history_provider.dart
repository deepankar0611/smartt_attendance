import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _userId;
  
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _isListView = true;
  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoading = true;

  // Getters
  DateTime get currentMonth => _currentMonth;
  DateTime get selectedDate => _selectedDate;
  bool get isListView => _isListView;
  List<Map<String, dynamic>> get attendanceData => _attendanceData;
  bool get isLoading => _isLoading;

  AttendanceHistoryProvider() {
    _userId = _auth.currentUser?.uid ?? '';
    if (_userId.isNotEmpty) {
      _fetchAttendanceByMonth(_currentMonth);
    }
  }

  Future<void> _fetchAttendanceByMonth(DateTime month) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('students')
          .doc(_userId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: DateTime(month.year, month.month, 1))
          .where('date', isLessThan: DateTime(month.year, month.month + 1, 1))
          .get();

      _attendanceData = snapshot.docs.map((doc) => doc.data()).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching attendance: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    _fetchAttendanceByMonth(_currentMonth);
  }

  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    _fetchAttendanceByMonth(_currentMonth);
  }

  void selectDate(DateTime selectedDay, DateTime focusedDay) {
    _selectedDate = selectedDay;
    notifyListeners();
  }

  void toggleListView(bool value) {
    _isListView = value;
    notifyListeners();
  }

  Map<String, dynamic>? getSelectedDayRecord(DateTime selectedDate) {
    for (var record in _attendanceData) {
      final date = record['date'];
      DateTime recordDate = date is Timestamp ? date.toDate() : DateTime.now();
      if (_isSameDay(recordDate, selectedDate)) {
        return record;
      }
    }
    return null;
  }

  Map<String, dynamic> getMonthlyStats() {
    if (_attendanceData.isEmpty) {
      return {
        'workdays': 0,
        'totalHours': '0h 0m',
        'avgHours': '0h 0m',
        'onTime': 0,
        'late': 0,
      };
    }

    int onTime = 0;
    int late = 0;
    int totalMinutes = 0;

    for (var record in _attendanceData) {
      if (record['status'] == 'On Time' || record['status'] == 'Early') {
        onTime++;
      } else if (record['status'] == 'Late') {
        late++;
      }

      String hoursStr = record['totalHours'] ?? '0h 0m';
      List<String> parts = hoursStr.split('h ');
      if (parts.length == 2) {
        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts[1].replaceAll('m', '')) ?? 0;
        totalMinutes += (hours * 60) + minutes;
      }
    }

    int avgMinutes = _attendanceData.isNotEmpty ? (totalMinutes / _attendanceData.length).round() : 0;
    String avgHours = '${avgMinutes ~/ 60}h ${avgMinutes % 60}m';
    String totalHoursFormatted = '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';

    return {
      'workdays': _attendanceData.length,
      'totalHours': totalHoursFormatted,
      'avgHours': avgHours,
      'onTime': onTime,
      'late': late,
    };
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'On Time':
        return Colors.green;
      case 'Late':
        return Colors.orange;
      case 'Early':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<String> getPlaceName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String? placeName = [place.street, place.name, place.locality]
            .firstWhere((element) => element != null && element.isNotEmpty, orElse: () => null);
        return placeName ?? 'Unknown Location';
      }
      return 'Unknown Location';
    } catch (e) {
      print('Error geocoding coordinates ($latitude, $longitude): $e');
      return 'Unable to fetch location';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
} 