import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../utils/attendance_utils.dart';

class EmployeeListProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;
  String _selectedDepartment = 'All Departments';
  bool _isLoading = true;

  // Data for tabs
  List<Map<String, dynamic>> _loggedInData = [];
  List<Map<String, dynamic>> _onTimeData = [];
  List<Map<String, dynamic>> _lateData = [];
  Map<String, Map<String, dynamic>> _jobStats = {};

  // Getters
  String get selectedDepartment => _selectedDepartment;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get loggedInData => _loggedInData;
  List<Map<String, dynamic>> get onTimeData => _onTimeData;
  List<Map<String, dynamic>> get lateData => _lateData;
  Map<String, Map<String, dynamic>> get jobStats => _jobStats;

  // Initialize
  void initialize() {
    _userId = _auth.currentUser?.uid ?? '';
    if (_userId.isEmpty) {
      print('No user is currently signed in.');
    }
    _fetchAttendanceData();
  }

  // Set selected department
  void setSelectedDepartment(String department) {
    _selectedDepartment = department;
    notifyListeners();
  }

  // Get address from coordinates
  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String street = placemark.street ?? 'Unknown location';
        return street.isNotEmpty ? street : 'Unknown location';
      }
    } catch (e) {
      print('Error decoding coordinates: $e');
    }
    return 'Unknown location';
  }

  // Initialize job statistics
  void _initializeJobStats() {
    _jobStats = {
      'software engineer': {
        'total': 0,
        'onTime': 0,
        'late': 0,
        'leave': 0,
      },
      'designer': {
        'total': 0,
        'onTime': 0,
        'late': 0,
        'leave': 0,
      },
      'data scientist': {
        'total': 0,
        'onTime': 0,
        'late': 0,
        'leave': 0,
      },
      'sales representative': {
        'total': 0,
        'onTime': 0,
        'late': 0,
        'leave': 0,
      },
      'customer support': {
        'total': 0,
        'onTime': 0,
        'late': 0,
        'leave': 0,
      },
      'finance manager': {
        'total': 0,
        'onTime': 0,
        'late': 0,
        'leave': 0,
      },
      'hr manager': {
        'total': 0,
        'onTime': 0,
        'late': 0,
        'leave': 0,
      },
      'marketing specialist': {
        'total': 0,
        'onTime': 0,
        'late': 0,
        'leave': 0,
      },
      'student': {
        'total': 0,
        'onTime': 0,
        'late': 0,
        'leave': 0,
      },
    };
  }

  // Fetch attendance data
  Future<void> _fetchAttendanceData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Initialize job statistics
      _initializeJobStats();

      // First get the current teacher's friends list
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('teachers')
          .doc(_userId)
          .collection('friends')
          .get();

      if (friendsSnapshot.docs.isEmpty) {
        print('No friends found for teacher: $_userId');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Extract friend UIDs from the subcollection
      List<String> friendUids = friendsSnapshot.docs
          .map((doc) => doc.get('friendId') as String)
          .toList();

      List<Map<String, dynamic>> loggedInList = [];
      List<Map<String, dynamic>> onTimeList = [];
      List<Map<String, dynamic>> lateList = [];

      for (String friendUid in friendUids) {
        // Get student document
        DocumentSnapshot studentDoc = await _firestore.collection('students').doc(friendUid).get();
        if (!studentDoc.exists) continue;

        final studentData = studentDoc.data() as Map<String, dynamic>;
        String job = (studentData['job'] ?? 'student').toLowerCase();

        // Get check-in and check-out times
        String loginTime = 'Not checked in';
        String checkOutTime = 'Not checked out';
        String status = 'Unknown';

        if (studentData['checkInTime'] != null) {
          if (studentData['checkInTime'] is Timestamp) {
            Timestamp checkInTimestamp = studentData['checkInTime'] as Timestamp;
            DateTime checkInDateTime = checkInTimestamp.toDate();
            loginTime = DateFormat('hh:mm a').format(checkInDateTime.toLocal());
          } else {
            // If it's a string, try to extract just the time
            String timeStr = studentData['checkInTime'] as String;
            RegExp timeRegex = RegExp(r'at (\d+:\d+):\d+ ([AP]M)');
            var match = timeRegex.firstMatch(timeStr);
            if (match != null) {
              loginTime = '${match.group(1)} ${match.group(2)}';
            } else {
              loginTime = timeStr;
            }
          }
        }

        if (studentData['checkOutTime'] != null) {
          if (studentData['checkOutTime'] is Timestamp) {
            Timestamp checkOutTimestamp = studentData['checkOutTime'] as Timestamp;
            DateTime checkOutDateTime = checkOutTimestamp.toDate();
            checkOutTime = DateFormat('hh:mm a').format(checkOutDateTime.toLocal());
          } else {
            // If it's a string, try to extract just the time
            String timeStr = studentData['checkOutTime'] as String;
            RegExp timeRegex = RegExp(r'at (\d+:\d+):\d+ ([AP]M)');
            var match = timeRegex.firstMatch(timeStr);
            if (match != null) {
              checkOutTime = '${match.group(1)} ${match.group(2)}';
            } else {
              checkOutTime = timeStr;
            }
          }
        }

        status = studentData['status'] ?? 'Unknown';

        // Get check-in location
        String checkInLocation = 'Not specified';
        if (studentData['checkInLocation'] != null) {
          double latitude = studentData['checkInLocation']['latitude']?.toDouble() ?? 0.0;
          double longitude = studentData['checkInLocation']['longitude']?.toDouble() ?? 0.0;
          if (latitude != 0.0 && longitude != 0.0) {
            checkInLocation = await _getAddressFromCoordinates(latitude, longitude);
          }
        }

        // Get check-out location
        String checkOutLocation = 'Not specified';
        if (studentData['checkOutLocation'] != null) {
          double latitude = studentData['checkOutLocation']['latitude']?.toDouble() ?? 0.0;
          double longitude = studentData['checkOutLocation']['longitude']?.toDouble() ?? 0.0;
          if (latitude != 0.0 && longitude != 0.0) {
            checkOutLocation = await _getAddressFromCoordinates(latitude, longitude);
          }
        }

        String? lateDuration;

        // Calculate late duration if status is Late
        if (status == 'Late' && studentData['checkInTime'] != null) {
          if (studentData['checkInTime'] is Timestamp) {
            Timestamp checkInTimestamp = studentData['checkInTime'] as Timestamp;
            DateTime checkInDateTime = checkInTimestamp.toDate().toLocal();
            DateTime lateAfterTime = DateTime(
              checkInDateTime.year,
              checkInDateTime.month,
              checkInDateTime.day,
              9, // 9 AM
              0,
            );

            if (checkInDateTime.isAfter(lateAfterTime)) {
              Duration difference = checkInDateTime.difference(lateAfterTime);
              lateDuration = '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
            }
          }
        }

        // Update job statistics
        if (_jobStats.containsKey(job)) {
          _jobStats[job]!['total'] = (_jobStats[job]!['total'] as int) + 1;
          
          if (status == 'On Time') {
            _jobStats[job]!['onTime'] = (_jobStats[job]!['onTime'] as int) + 1;
          } else if (status == 'Late') {
            _jobStats[job]!['late'] = (_jobStats[job]!['late'] as int) + 1;
          } else {
            _jobStats[job]!['leave'] = (_jobStats[job]!['leave'] as int) + 1;
          }
        }

        Map<String, dynamic> employee = {
          'name': studentData['name'] ?? 'Unknown',
          'position': job,
          'status': 'Regular',
          'loginTime': loginTime,
          'checkOutTime': checkOutTime,
          'attendance': status,
          'avatar': _getAvatarColor(studentData['name']),
          'checkInLocation': checkInLocation,
          'checkOutLocation': checkOutLocation,
          'lateDuration': lateDuration,
          'totalHours': studentData['totalHours'] ?? '0h 0m',
        };

        loggedInList.add(employee);
        if (status == 'On Time') {
          onTimeList.add(employee);
        } else if (status == 'Late') {
          lateList.add(employee);
        }
      }

      _loggedInData = loggedInList;
      _onTimeData = onTimeList;
      _lateData = lateList;
      _isLoading = false;
      notifyListeners();

    } catch (e) {
      print('Error fetching attendance data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get avatar color
  Color _getAvatarColor(String? name) {
    if (name == null) return Colors.grey[400]!;
    int hash = name.hashCode;
    List<Color> colors = [
      Colors.blue[200]!,
      Colors.purple[200]!,
      Colors.orange[200]!,
      Colors.green[200]!,
      Colors.red[200]!,
      Colors.teal[200]!,
      Colors.amber[200]!,
    ];
    return colors[hash % colors.length];
  }

  // Helper method to get department details
  Map<String, dynamic> getDepartmentDetails(String job) {
    switch (job.toLowerCase()) {
      case 'software engineer':
        return {
          'title': 'Development',
          'icon': Icons.code,
          'iconColor': Colors.purple,
        };
      case 'designer':
        return {
          'title': 'Design',
          'icon': Icons.design_services,
          'iconColor': Colors.blue,
        };
      case 'data scientist':
        return {
          'title': 'Data Science',
          'icon': Icons.analytics,
          'iconColor': Colors.green,
        };
      case 'sales representative':
        return {
          'title': 'Sales',
          'icon': Icons.people,
          'iconColor': Colors.orange,
        };
      case 'customer support':
        return {
          'title': 'Customer Support',
          'icon': Icons.support_agent,
          'iconColor': Colors.red,
        };
      case 'finance manager':
        return {
          'title': 'Finance',
          'icon': Icons.money,
          'iconColor': Colors.green,
        };
      case 'hr manager':
        return {
          'title': 'HR',
          'icon': Icons.person,
          'iconColor': Colors.deepPurple,
        };
      case 'marketing specialist':
        return {
          'title': 'Marketing',
          'icon': Icons.shopping_cart,
          'iconColor': Colors.amber,
        };
      default:
        return {
          'title': job,
          'icon': Icons.work,
          'iconColor': Colors.teal,
        };
    }
  }

  // Helper method to get position icon
  IconData getPositionIcon(String position) {
    switch (position.toLowerCase()) {
      case 'student':
        return Icons.school;
      case 'software engineer':
        return Icons.code;
      case 'designer':
        return Icons.design_services;
      case 'data scientist':
        return Icons.analytics;
      case 'sales representative':
        return Icons.people;
      case 'customer support':
        return Icons.support_agent;
      case 'finance manager':
        return Icons.money;
      case 'hr manager':
        return Icons.person;
      case 'marketing specialist':
        return Icons.shopping_cart;
      default:
        return Icons.work;
    }
  }
} 