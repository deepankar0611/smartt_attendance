import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LeaveProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedLeaveType = 'Casual Leave';
  final List<String> _leaveTypes = ['Casual Leave', 'Sick Leave', 'Vacation', 'Personal'];
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  // Getters
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get selectedLeaveType => _selectedLeaveType;
  List<String> get leaveTypes => _leaveTypes;
  TextEditingController get reasonController => _reasonController;
  bool get isSubmitting => _isSubmitting;

  // Setters
  void setStartDate(DateTime? date) {
    _startDate = date;
    if (_endDate != null && _endDate!.isBefore(_startDate!)) {
      _endDate = _startDate;
    }
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }

  void setLeaveType(String type) {
    _selectedLeaveType = type;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  Future<void> submitApplication(BuildContext context) async {
    if (_startDate == null || _endDate == null || _reasonController.text.trim().isEmpty) {
      return;
    }

    setSubmitting(true);
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final leaveData = {
        'studentId': userId,
        'leaveType': _selectedLeaveType,
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'reason': _reasonController.text.trim(),
        'status': 'Pending',
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('students')
          .doc(userId)
          .collection('leaves')
          .add(leaveData);

      // Reset form
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
      _selectedLeaveType = 'Casual Leave';
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Leave application submitted successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              Text('Failed to submit leave application: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setSubmitting(false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
} 