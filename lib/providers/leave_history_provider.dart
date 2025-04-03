import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveHistoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _leaves = [];

  // Getters
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get leaves => _leaves;

  // Stream for real-time updates
  Stream<QuerySnapshot> get leaveStream {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('students')
        .doc(userId)
        .collection('leaves')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // Load leaves
  Future<void> loadLeaves() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection('students')
          .doc(userId)
          .collection('leaves')
          .orderBy('submittedAt', descending: true)
          .get();

      _leaves = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error loading leaves: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete leave
  Future<void> deleteLeave(String leaveId) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('students')
          .doc(userId)
          .collection('leaves')
          .doc(leaveId)
          .delete();

      _leaves.removeWhere((leave) => leave['id'] == leaveId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting leave: $e');
      rethrow;
    }
  }

  // Update leave status
  Future<void> updateLeaveStatus(String leaveId, String status) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('students')
          .doc(userId)
          .collection('leaves')
          .doc(leaveId)
          .update({'status': status});

      final index = _leaves.indexWhere((leave) => leave['id'] == leaveId);
      if (index != -1) {
        _leaves[index]['status'] = status;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating leave status: $e');
      rethrow;
    }
  }
} 