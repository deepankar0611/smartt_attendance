import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceScreenProvider extends ChangeNotifier {
  bool _isCheckedIn = false;
  DateTime? _checkInDateTime;
  Timestamp? _checkInTimestamp;
  Timestamp? _checkOutTimestamp;
  String? _totalHours;
  Position? _checkInLocation;
  Position? _checkOutLocation;
  String? _userName;
  String? _profileImageUrl;
  String? _email;
  String? _mobile;
  String? _teacherId;
  Map<String, dynamic>? _officeTimings;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _userId;

  // Getters
  bool get isCheckedIn => _isCheckedIn;
  DateTime? get checkInDateTime => _checkInDateTime;
  Timestamp? get checkInTimestamp => _checkInTimestamp;
  Timestamp? get checkOutTimestamp => _checkOutTimestamp;
  String? get totalHours => _totalHours;
  Position? get checkInLocation => _checkInLocation;
  Position? get checkOutLocation => _checkOutLocation;
  String? get userName => _userName;
  String? get profileImageUrl => _profileImageUrl;
  String? get email => _email;
  String? get mobile => _mobile;
  Map<String, dynamic>? get officeTimings => _officeTimings;

  AttendanceScreenProvider() {
    _userId = _auth.currentUser?.uid ?? '';
    if (_userId.isNotEmpty) {
      initialize();
    }
  }

  Future<void> initialize() async {
    await _fetchUserData();
    await _fetchTeacherId();
    await _loadCurrentStatus();
    await _requestLocationPermission();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('students').doc(_userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _userName = data['name'] ?? 'User';
        _email = data['email'] ?? _auth.currentUser?.email ?? 'unknown';
        _mobile = data['mobile'] ?? 'Not provided';
        _profileImageUrl = data['profileImageUrl'];
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchTeacherId() async {
    try {
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('students')
          .doc(_userId)
          .collection('friends')
          .get();

      if (friendsSnapshot.docs.isNotEmpty) {
        final friendDoc = friendsSnapshot.docs.first;
        final friendData = friendDoc.data() as Map<String, dynamic>;
        _teacherId = friendData['friendId'] as String?;
        if (_teacherId != null) {
          await _fetchOfficeTimings();
        }
      }
    } catch (e) {
      print('Error fetching teacher ID: $e');
    }
  }

  Future<void> _fetchOfficeTimings() async {
    try {
      if (_teacherId == null) return;
      
      final timingDoc = await _firestore
          .collection('teachers')
          .doc(_teacherId)
          .collection('office_timings')
          .doc('current')
          .get();

      if (timingDoc.exists) {
        _officeTimings = timingDoc.data();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching office timings: $e');
    }
  }

  Future<void> _loadCurrentStatus() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('students').doc(_userId).get();
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final checkInTime = data['checkInTime'] as Timestamp?;
        final checkOutTime = data['checkOutTime'] as Timestamp?;
        
        if (checkInTime != null) {
          _checkInTimestamp = checkInTime;
          _checkInDateTime = checkInTime.toDate();
          _isCheckedIn = checkOutTime == null;
          
          if (checkOutTime != null) {
            _checkOutTimestamp = checkOutTime;
            _totalHours = data['totalHours'];
          }
        } else {
          _isCheckedIn = false;
          _checkInDateTime = null;
          _checkInTimestamp = null;
          _checkOutTimestamp = null;
          _totalHours = null;
        }
        notifyListeners();

        if (_isCheckedIn) {
          final querySnapshot = await _firestore
              .collection('students')
              .doc(_userId)
              .collection('attendance')
              .orderBy('checkInTime', descending: true)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final attendanceData = querySnapshot.docs.first.data();
            // Update any additional attendance-specific data if needed
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error loading status: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  String _determineAttendanceStatus(DateTime checkInTime) {
    if (_officeTimings == null) {
      print('No office timings available'); 
      return 'Status Not Available';
    }

    try {
      final lateAfterTime = (_officeTimings!['lateAfterTime'] as Timestamp).toDate();
      
      final checkInTimeOnly = DateTime(
        checkInTime.year,
        checkInTime.month,
        checkInTime.day,
        checkInTime.hour,
        checkInTime.minute,
      );
      
      final lateAfterTimeToday = DateTime(
        checkInTime.year,
        checkInTime.month,
        checkInTime.day,
        lateAfterTime.hour,
        lateAfterTime.minute,
      );
      
      if (checkInTimeOnly.isAfter(lateAfterTimeToday)) {
        return 'Late';
      } else {
        return 'On Time';
      }
    } catch (e) {
      print('Error determining attendance status: $e');
      return 'Status Error';
    }
  }

  Future<void> handleCheckIn(DateTime punchTime) async {
    try {
      if (_teacherId == null || _officeTimings == null) {
        print('Teacher ID or office timings not available');
        return;
      }

      _checkInLocation = await _getCurrentLocation();
      final timestamp = Timestamp.fromDate(punchTime);
      final status = _determineAttendanceStatus(punchTime);
      
      // Update student document
      await _firestore.collection('students').doc(_userId).set({
        'checkInTime': timestamp,
        'checkInLocation': {
          'latitude': _checkInLocation!.latitude,
          'longitude': _checkInLocation!.longitude,
        },
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create attendance record
      await _firestore
          .collection('students')
          .doc(_userId)
          .collection('attendance')
          .add({
        'checkInTime': timestamp,
        'checkInLocation': {
          'latitude': _checkInLocation!.latitude,
          'longitude': _checkInLocation!.longitude,
        },
        'status': status,
        'date': timestamp,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _isCheckedIn = true;
      _checkInDateTime = punchTime;
      _checkInTimestamp = timestamp;
      _checkOutTimestamp = null;
      _totalHours = null;
      notifyListeners();
    } catch (e) {
      print('Error during check-in: $e');
      throw e;
    }
  }

  Future<void> handleCheckOut(DateTime punchTime) async {
    try {
      _checkOutLocation = await _getCurrentLocation();
      final timestamp = Timestamp.fromDate(punchTime);
      String totalHours = '';
      
      if (_checkInDateTime != null) {
        Duration difference = punchTime.difference(_checkInDateTime!);
        int hours = difference.inHours;
        int minutes = difference.inMinutes.remainder(60);
        totalHours = "${hours}h ${minutes}m";
      }

      // Update student document
      await _firestore.collection('students').doc(_userId).set({
        'checkOutTime': timestamp,
        'checkOutLocation': {
          'latitude': _checkOutLocation!.latitude,
          'longitude': _checkOutLocation!.longitude,
        },
        'totalHours': totalHours,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update attendance record
      final querySnapshot = await _firestore
          .collection('students')
          .doc(_userId)
          .collection('attendance')
          .orderBy('checkInTime', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final attendanceDoc = querySnapshot.docs.first;
        await attendanceDoc.reference.update({
          'checkOutTime': timestamp,
          'checkOutLocation': {
            'latitude': _checkOutLocation!.latitude,
            'longitude': _checkOutLocation!.longitude,
          },
          'totalHours': totalHours,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      _checkOutTimestamp = timestamp;
      _totalHours = totalHours;
      _isCheckedIn = false;
      notifyListeners();
    } catch (e) {
      print('Error during check-out: $e');
      throw e;
    }
  }
} 