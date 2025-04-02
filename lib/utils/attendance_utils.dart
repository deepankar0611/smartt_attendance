import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceStatus {
  static const String onTime = 'On Time';
  static const String late = 'Late';
  static const String absent = 'Absent';
  static const String earlyCheckout = 'Early Checkout';
}

class AttendanceUtils {
  static Future<String> calculateAttendanceStatus(
    DateTime checkInTime,
    DateTime? checkOutTime,
    {String? teacherId}
  ) async {
    try {
      if (teacherId == null) {
        return AttendanceStatus.onTime; // Default if no teacher ID provided
      }

      // Get teacher's personal settings
      final settings = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('office_timings')
          .doc('current')
          .get();

      if (!settings.exists) {
        return AttendanceStatus.onTime; // Default if no settings found
      }

      final data = settings.data() as Map<String, dynamic>;
      final lateAfterTimestamp = data['lateAfterTime'] as Timestamp;
      final checkOutTimestamp = data['checkOutTime'] as Timestamp;

      // Convert timestamps to DateTime for the current day
      final now = DateTime.now();
      final lateAfterTime = _setTimeForToday(lateAfterTimestamp.toDate());
      final checkOutTime2 = _setTimeForToday(checkOutTimestamp.toDate());
      final checkInTime2 = _setTimeForToday(checkInTime);
      final checkOutTime3 = checkOutTime != null ? _setTimeForToday(checkOutTime) : null;

      // Check if late
      if (checkInTime2.isAfter(lateAfterTime)) {
        return AttendanceStatus.late;
      }

      // Check if early checkout
      if (checkOutTime3 != null && checkOutTime3.isBefore(checkOutTime2)) {
        return AttendanceStatus.earlyCheckout;
      }

      return AttendanceStatus.onTime;
    } catch (e) {
      print('Error calculating attendance status: $e');
      return AttendanceStatus.onTime; // Default in case of error
    }
  }

  static DateTime _setTimeForToday(DateTime dateTime) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      dateTime.hour,
      dateTime.minute,
    );
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
} 