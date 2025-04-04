import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class AdminProfileProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _profileImageUrl;
  String _name = "Admin User";
  String _location = "Head Office";
  String _mobile = "7479519946";
  String _email = "admin@example.com";
  String _joinDate = "01-01-2023";
  bool _isUploading = false;
  final Map<String, int> _stats = {
    'employees': 0,
    'projects': 12,
  };

  // Getters
  String? get profileImageUrl => _profileImageUrl;
  String get name => _name;
  String get location => _location;
  String get mobile => _mobile;
  String get email => _email;
  String get joinDate => _joinDate;
  bool get isUploading => _isUploading;
  Map<String, int> get stats => _stats;

  Future<void> fetchAdminProfile(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('teachers').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String formattedJoinDate = "01-01-2023";
        if (data['createdAt'] != null) {
          Timestamp createdAt = data['createdAt'] as Timestamp;
          DateTime dateTime = createdAt.toDate();
          formattedJoinDate = DateFormat('dd-MM-yyyy').format(dateTime);
        }

        _name = data['name'] ?? "Admin User";
        _location = data['location'] ?? "Head Office";
        _mobile = data['mobile'] ?? "7479519946";
        _email = data['email'] ?? "admin@example.com";
        _joinDate = formattedJoinDate;
        _profileImageUrl = data['profileImageUrl'];
        notifyListeners();
      } else {
        await _firestore.collection('teachers').doc(userId).set({
          'name': _name,
          'location': _location,
          'mobile': _mobile,
          'email': _auth.currentUser?.email ?? 'admin@example.com',
          'joinDate': _joinDate,
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': _auth.currentUser?.emailVerified ?? false,
          'profileImageUrl': null,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error fetching admin profile: $e');
    }
  }

  Future<void> fetchSummaryData(String userId) async {
    try {
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('teachers')
          .doc(userId)
          .collection('friends')
          .get();
      int totalFriends = friendsSnapshot.docs.length;

      QuerySnapshot projectsSnapshot = await _firestore.collection('projects').get();
      int activeProjects = projectsSnapshot.docs.length;

      _stats['employees'] = totalFriends;
      _stats['projects'] = activeProjects;
      notifyListeners();
    } catch (e) {
      print('Error fetching summary data: $e');
    }
  }

  Future<void> pickAndUploadImage(String userId) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      _isUploading = true;
      notifyListeners();

      String fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
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

      await _firestore.collection('teachers').doc(userId).update({
        'profileImageUrl': imageUrl,
      });

      _profileImageUrl = imageUrl;
      _isUploading = false;
      notifyListeners();
    } catch (e) {
      _isUploading = false;
      notifyListeners();
      print('Error uploading image: $e');
    }
  }

  Future<void> updateProfile(String userId, String name, String location, String mobile) async {
    try {
      _name = name;
      _location = location;
      _mobile = mobile;
      notifyListeners();

      await _firestore.collection('teachers').doc(userId).update({
        'name': name,
        'location': location,
        'mobile': mobile,
      });
    } catch (e) {
      print('Error updating admin profile: $e');
    }
  }
} 