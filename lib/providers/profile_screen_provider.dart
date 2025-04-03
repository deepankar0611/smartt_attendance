import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreenProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  String? _profileImageUrl;
  String _name = "";
  String _job = "";
  String _location = "";
  String _mobile = "";
  bool _isLoading = true;
  bool _isUploading = false;
  String _userId = '';
  
  final Map<String, int> _stats = {
    'Projects': 0,
    'Attended': 0,
    'Leaves': 0,
  };

  // Getters
  String? get profileImageUrl => _profileImageUrl;
  String get name => _name;
  String get job => _job;
  String get location => _location;
  String get mobile => _mobile;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  Map<String, int> get stats => _stats;

  ProfileScreenProvider() {
    _userId = _auth.currentUser?.uid ?? '';
    if (_userId.isNotEmpty) {
      initializeData();
    }
  }

  Future<void> initializeData() async {
    try {
      await Future.wait([
        _fetchUserProfile(),
        _fetchAttendanceStats(),
        _fetchProjectCount(),
        _fetchLeaveCount(),
      ]);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('students').doc(_userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _name = data['name'] ?? "User";
        _job = data['job'] ?? "Loading";
        _location = data['location'] ?? "Chandigarh";
        _mobile = data['mobile'] ?? "7479519946";
        _stats['Projects'] = data['projects'] ?? 0;
        _profileImageUrl = data['profileImageUrl'];
        notifyListeners();
      } else {
        await _firestore.collection('students').doc(_userId).set({
          'name': _name,
          'job': _job,
          'location': _location,
          'mobile': _mobile,
          'projects': _stats['Projects'],
          'createdAt': FieldValue.serverTimestamp(),
          'email': _auth.currentUser?.email ?? 'unknown',
          'isEmailVerified': _auth.currentUser?.emailVerified ?? false,
          'role': 'student',
          'profileImageUrl': null,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _fetchAttendanceStats() async {
    try {
      DateTime now = DateTime.now();
      final snapshot = await _firestore
          .collection('students')
          .doc(_userId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: DateTime(now.year, now.month, 1))
          .where('date', isLessThan: DateTime(now.year, now.month + 1, 1))
          .get();

      int attendedDays = snapshot.docs.length;
      _stats['Attended'] = attendedDays;
      notifyListeners();
    } catch (e) {
      print('Error fetching attendance stats: $e');
    }
  }

  Future<void> _fetchProjectCount() async {
    try {
      QuerySnapshot creatorProjects = await _firestore
          .collection('projects')
          .where('creatorUid', isEqualTo: _userId)
          .get();

      QuerySnapshot employeeProjects = await _firestore
          .collection('projects')
          .where('employeeUids', arrayContains: _userId)
          .get();

      Set<String> projectIds = {};
      
      for (var doc in creatorProjects.docs) {
        projectIds.add(doc.id);
      }
      
      for (var doc in employeeProjects.docs) {
        projectIds.add(doc.id);
      }

      _stats['Projects'] = projectIds.length;
      notifyListeners();
    } catch (e) {
      print('Error fetching project count: $e');
      _stats['Projects'] = 0;
      notifyListeners();
    }
  }

  Future<void> _fetchLeaveCount() async {
    try {
      final leavesRef = _firestore
          .collection('students')
          .doc(_userId)
          .collection('leaves');

      QuerySnapshot leavesSnapshot = await leavesRef
          .where('status', isEqualTo: 'Approved')
          .where('startDate', isGreaterThanOrEqualTo: DateTime(DateTime.now().year, DateTime.now().month, 1))
          .where('startDate', isLessThan: DateTime(DateTime.now().year, DateTime.now().month + 1, 1))
          .get();

      int totalLeaveDays = 0;
      for (var doc in leavesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['startDate'] != null && data['endDate'] != null) {
          DateTime startDate = (data['startDate'] as Timestamp).toDate();
          DateTime endDate = (data['endDate'] as Timestamp).toDate();
          int days = endDate.difference(startDate).inDays + 1;
          totalLeaveDays += days;
        }
      }

      _stats['Leaves'] = totalLeaveDays;
      notifyListeners();
    } catch (e) {
      print('Error fetching leave count: $e');
      _stats['Leaves'] = 0;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String name,
    required String job,
    required String location,
    required String mobile,
    required int projects,
  }) async {
    try {
      await _firestore.collection('students').doc(_userId).update({
        'name': name,
        'job': job,
        'location': location,
        'mobile': mobile,
        'projects': projects,
      });

      _name = name;
      _job = job;
      _location = location;
      _mobile = mobile;
      _stats['Projects'] = projects;
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      throw e;
    }
  }

  Future<void> pickAndUploadImage(BuildContext context, ImageSource source) async {
    try {
      _isUploading = true;
      notifyListeners();

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        _isUploading = false;
        notifyListeners();
        return;
      }

      String fileName = '$_userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      File imageFile = File(pickedFile.path);

      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        String oldFileName = _profileImageUrl!.split('/').last;
        try {
          await _supabase.storage.from('profile_pictures').remove([oldFileName]);
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      await _supabase.storage
          .from('profile_pictures')
          .upload(fileName, imageFile, fileOptions: const FileOptions(upsert: true));

      final String imageUrl = _supabase.storage.from('profile_pictures').getPublicUrl(fileName);

      await _firestore.collection('students').doc(_userId).update({
        'profileImageUrl': imageUrl,
      });

      _profileImageUrl = imageUrl;
      notifyListeners();
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
} 