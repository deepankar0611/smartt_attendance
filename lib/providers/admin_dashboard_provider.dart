import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/attendance_utils.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;
  String? _profileImageUrl;
  bool _isImageLoading = true;
  bool _isMenuOpen = false;
  bool _isLoading = true;

  Map<String, dynamic> _summaryData = {
    'totalEmployees': 0,
    'totalEmployeesChange': 0.0,
    'presentToday': 0,
    'presentTodayChange': 0.0,
    'onLeave': 0,
    'activeProjects': 0,
  };
  List<Map<String, dynamic>> _projects = [];

  // Getters
  String? get profileImageUrl => _profileImageUrl;
  bool get isImageLoading => _isImageLoading;
  bool get isMenuOpen => _isMenuOpen;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get summaryData => _summaryData;
  List<Map<String, dynamic>> get projects => _projects;

  // Initialize
  void initialize() {
    _userId = _auth.currentUser?.uid ?? '';
    if (_userId.isEmpty) {
      print('No user is currently signed in.');
    }
    _fetchDashboardData();
    _loadProfileImage();
  }

  // Toggle menu
  void toggleMenu() {
    _isMenuOpen = !_isMenuOpen;
    notifyListeners();
  }

  // Fetch dashboard data
  Future<void> _fetchDashboardData() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _fetchSummaryData();
      await _fetchProjects();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching dashboard data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch summary data
  Future<void> _fetchSummaryData() async {
    try {
      // Fetch friends
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('teachers')
          .doc(_userId)
          .collection('friends')
          .get();
      int totalFriends = friendsSnapshot.docs.length;

      // Calculate total friends change
      double totalFriendsChange = 0.0;
      DateTime now = DateTime.now();
      DateTime firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
      DateTime lastDayOfPreviousMonth = firstDayOfCurrentMonth.subtract(Duration(days: 1));
      QuerySnapshot previousFriendsSnapshot = await _firestore
          .collection('teachers')
          .doc(_userId)
          .collection('friendHistory')
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfPreviousMonth))
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (previousFriendsSnapshot.docs.isNotEmpty) {
        int previousFriendsCount = previousFriendsSnapshot.docs.first.get('count') ?? 0;
        if (previousFriendsCount > 0) {
          totalFriendsChange = ((totalFriends - previousFriendsCount) / previousFriendsCount) * 100;
        }
      }

      List<String> friendUids = friendsSnapshot.docs
          .map((doc) => doc.get('friendId') as String)
          .toList();

      int presentToday = 0;
      int onLeave = 0;
      DateTime today = DateTime.now();
      today = DateTime(today.year, today.month, today.day);

      for (String friendUid in friendUids) {
        DocumentSnapshot studentDoc = await _firestore.collection('students').doc(friendUid).get();
        if (studentDoc.exists) {
          var data = studentDoc.data() as Map<String, dynamic>;

          // Check for present today
          if (data.containsKey('checkInTime') && data['checkInTime'] != null) {
            try {
              Timestamp checkInTimestamp = data['checkInTime'] as Timestamp;
              DateTime checkInDate = checkInTimestamp.toDate();
              DateTime checkInDateOnly = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
              
              if (checkInDateOnly.isAtSameMomentAs(today)) {
                presentToday++;
              }
            } catch (e) {
              print('Error parsing checkInTime for $friendUid: $e');
            }
          }

          // Check for leaves
          QuerySnapshot leaveSnapshot = await _firestore
              .collection('students')
              .doc(friendUid)
              .collection('leaves')
              .get();

          for (var leaveDoc in leaveSnapshot.docs) {
            var leaveData = leaveDoc.data() as Map<String, dynamic>;
            if (leaveData.containsKey('startDate') && leaveData.containsKey('endDate')) {
              try {
                Timestamp startTimestamp = leaveData['startDate'] as Timestamp;
                Timestamp endTimestamp = leaveData['endDate'] as Timestamp;
                
                DateTime startDate = startTimestamp.toDate();
                DateTime endDate = endTimestamp.toDate();

                if (today.isAfter(startDate.subtract(Duration(days: 1))) &&
                    today.isBefore(endDate.add(Duration(days: 1)))) {
                  onLeave++;
                }
              } catch (e) {
                print('Error parsing leave dates for $friendUid: $e');
              }
            }
          }
        }
      }

      double presentTodayChange = 0.0;
      DateTime yesterday = today.subtract(Duration(days: 1));
      QuerySnapshot yesterdayAttendanceSnapshot = await _firestore
          .collection('attendanceRecords')
          .where('date', isEqualTo: Timestamp.fromDate(yesterday))
          .limit(1)
          .get();

      if (yesterdayAttendanceSnapshot.docs.isNotEmpty) {
        int yesterdayPresent = yesterdayAttendanceSnapshot.docs.first.get('present') ?? 0;
        if (yesterdayPresent > 0) {
          presentTodayChange = ((presentToday - yesterdayPresent) / yesterdayPresent) * 100;
        }
      }

      QuerySnapshot projectsSnapshot = await _firestore.collection('projects').get();
      int activeProjects = projectsSnapshot.docs.length;

      _summaryData = {
        'totalEmployees': totalFriends,
        'totalEmployeesChange': totalFriendsChange,
        'presentToday': presentToday,
        'presentTodayChange': presentTodayChange,
        'onLeave': onLeave,
        'activeProjects': activeProjects,
      };
      notifyListeners();
    } catch (e) {
      print('Error fetching summary data: $e');
    }
  }

  // Fetch projects
  Future<void> _fetchProjects() async {
    QuerySnapshot projectsSnapshot = await _firestore.collection('projects').get();
    _projects = projectsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        'name': data['name'] ?? 'Unknown',
        'team': data['team'] ?? 'Unknown',
        'deadline': DateFormat('dd MMM').format((data['deadline'] as Timestamp).toDate()),
        'progress': (data['progress'] ?? 0).toDouble(),
        'color': _getTeamColor(data['team']),
      };
    }).toList();
    notifyListeners();
  }

  // Load profile image
  Future<void> _loadProfileImage() async {
    try {
      if (_userId.isEmpty) return;
      final teacherDoc = await _firestore.collection('teachers').doc(_userId).get();
      if (teacherDoc.exists) {
        _profileImageUrl = teacherDoc.data()?['profileImageUrl'];
        _isImageLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading profile image: $e');
      _isImageLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get team color
  Color _getTeamColor(String team) {
    switch (team.toLowerCase()) {
      case 'development':
        return Colors.purple;
      case 'design':
        return Colors.blue;
      case 'ui/ux':
        return Colors.green;
      case 'qa team':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 