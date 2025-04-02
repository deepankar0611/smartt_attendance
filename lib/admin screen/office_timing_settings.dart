import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfficeTimingSettings extends StatefulWidget {
  const OfficeTimingSettings({Key? key}) : super(key: key);

  @override
  _OfficeTimingSettingsState createState() => _OfficeTimingSettingsState();
}

class _OfficeTimingSettingsState extends State<OfficeTimingSettings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;
  TimeOfDay? _lateAfterTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimings();
  }

  Future<void> _loadTimings() async {
    try {
      setState(() => _isLoading = true);
      
      // Load from teacher's personal settings
      final teacherDoc = await _firestore
          .collection('teachers')
          .doc(_auth.currentUser?.uid)
          .collection('office_timings')
          .doc('current')
          .get();

      if (teacherDoc.exists) {
        final data = teacherDoc.data()!;
        setState(() {
          _checkInTime = _timeFromTimestamp(data['checkInTime'] as Timestamp?);
          _checkOutTime = _timeFromTimestamp(data['checkOutTime'] as Timestamp?);
          _lateAfterTime = _timeFromTimestamp(data['lateAfterTime'] as Timestamp?);
        });
      }
    } catch (e) {
      _showSnackBar('Error loading timings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  TimeOfDay? _timeFromTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return null;
    final dateTime = timestamp.toDate();
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  Timestamp _timeToTimestamp(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return Timestamp.fromDate(dateTime);
  }

  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, String title, TimeOfDay? initialTime, Function(TimeOfDay) onSelect) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade900,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelect(picked);
    }
  }

  Future<void> _saveTimings() async {
    if (_checkInTime == null || _checkOutTime == null || _lateAfterTime == null) {
      _showSnackBar('Please set all timings');
      return;
    }

    try {
      final currentTime = FieldValue.serverTimestamp();
      final timingData = {
        'checkInTime': _timeToTimestamp(_checkInTime!),
        'checkOutTime': _timeToTimestamp(_checkOutTime!),
        'lateAfterTime': _timeToTimestamp(_lateAfterTime!),
        'displayCheckInTime': _timeToString(_checkInTime!),
        'displayCheckOutTime': _timeToString(_checkOutTime!),
        'displayLateAfterTime': _timeToString(_lateAfterTime!),
        'updatedAt': currentTime,
        'updatedBy': _auth.currentUser?.uid,
      };

      // Save only to teacher's personal settings
      await _firestore
          .collection('teachers')
          .doc(_auth.currentUser?.uid)
          .collection('office_timings')
          .doc('current')
          .set(timingData);

      _showSnackBar('Timings saved successfully');
    } catch (e) {
      _showSnackBar('Error saving timings: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: const Text('Office Timing Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    title: 'Office Hours',
                    children: [
                      _buildTimingTile(
                        'Check-in Time',
                        _checkInTime,
                        (time) => setState(() => _checkInTime = time),
                        Icons.login,
                      ),
                      const Divider(),
                      _buildTimingTile(
                        'Check-out Time',
                        _checkOutTime,
                        (time) => setState(() => _checkOutTime = time),
                        Icons.logout,
                      ),
                      const Divider(),
                      _buildTimingTile(
                        'Late After',
                        _lateAfterTime,
                        (time) => setState(() => _lateAfterTime = time),
                        Icons.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveTimings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Timings',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTimingTile(
    String title,
    TimeOfDay? time,
    Function(TimeOfDay) onSelect,
    IconData icon,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.green.shade900),
      ),
      title: Text(title),
      subtitle: Text(
        time != null ? _timeToString(time) : 'Not set',
        style: TextStyle(
          color: time != null ? Colors.black87 : Colors.grey,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.access_time),
        onPressed: () => _selectTime(context, title, time, onSelect),
      ),
    );
  }
} 