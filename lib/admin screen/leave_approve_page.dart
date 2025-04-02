import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> _friendIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      final String? teacherId = _auth.currentUser?.uid;
      if (teacherId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User not authenticated'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      final friendsSnapshot = await _firestore
          .collection('teachers')
          .doc(teacherId)
          .collection('friends')
          .get();

      setState(() {
        _friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching friends: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLeaveStatus(String studentId, String leaveId, String status) async {
    try {
      await _firestore
          .collection('students')
          .doc(studentId)
          .collection('leaves')
          .doc(leaveId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave $status successfully'),
          backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating leave status: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Leaves',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green, Color(0xFF1B5E20)],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friendIds.isEmpty
          ? const Center(child: Text('No students found in your friend list'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _friendIds.isNotEmpty
              ? _firestore
              .collectionGroup('leaves')
              .where('studentId', whereIn: _friendIds)
              .orderBy('submittedAt', descending: true)
              .snapshots()
              : null,
          builder: (context, leaveSnapshot) {
            if (_friendIds.isEmpty) {
              return const Center(child: Text('No students found in your friend list'));
            }

            if (leaveSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (leaveSnapshot.hasError) {
              return Center(child: Text('Error: ${leaveSnapshot.error}'));
            }
            if (!leaveSnapshot.hasData || leaveSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No leave applications found'));
            }

            final leaveDocs = leaveSnapshot.data!.docs;

            return ListView.builder(
              itemCount: leaveDocs.length,
              itemBuilder: (context, index) {
                final leaveData = leaveDocs[index].data() as Map<String, dynamic>;
                final studentId = leaveData['studentId'] as String;
                final leaveId = leaveDocs[index].id;
                final leaveType = leaveData['leaveType'] ?? 'Unknown';
                final startDate = (leaveData['startDate'] as Timestamp?)?.toDate();
                final endDate = (leaveData['endDate'] as Timestamp?)?.toDate();
                final reason = leaveData['reason'] ?? 'No reason provided';
                final status = leaveData['status'] ?? 'Pending';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              leaveType,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'Approved'
                                    ? Colors.green.withOpacity(0.2)
                                    : status == 'Rejected'
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'Approved'
                                      ? Colors.green
                                      : status == 'Rejected'
                                      ? Colors.red
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Student ID: $studentId',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'From: ${startDate != null ? DateFormat('MMM dd, yyyy').format(startDate) : 'N/A'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.event, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'To: ${endDate != null ? DateFormat('MMM dd, yyyy').format(endDate) : 'N/A'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reason: $reason',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 12),
                        if (status == 'Pending')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () => _updateLeaveStatus(studentId, leaveId, 'Approved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Approve'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _updateLeaveStatus(studentId, leaveId, 'Rejected'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}