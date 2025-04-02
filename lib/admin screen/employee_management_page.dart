import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'employee_details_page.dart';
import 'office_timing_settings.dart';

class EmployeeManagementPage extends StatefulWidget {
  const EmployeeManagementPage({Key? key}) : super(key: key);

  @override
  _EmployeeManagementPageState createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _adminId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _adminId = _auth.currentUser?.uid ?? '';
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch employees from friends collection
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('teachers')
          .doc(_adminId)
          .collection('friends')
          .get();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching employees: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          right: 20,
          left: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        elevation: 0,
        title: const Text(
          'Employee Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('teachers')
                  .doc(_adminId)
                  .collection('friends')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
                }

                final employees = snapshot.data!.docs;

                if (employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No employees found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add employees to see them here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    final studentId = employee.id; // This is the student's UID

                    return StreamBuilder<DocumentSnapshot>(
                      stream: _firestore.collection('students').doc(studentId).snapshots(),
                      builder: (context, studentSnapshot) {
                        if (!studentSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          );
                        }

                        final studentData = studentSnapshot.data!.data() as Map<String, dynamic>?;
                        if (studentData == null) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: const Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 16),
                                Text(
                                  'Student data not found',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final name = studentData['name'] ?? 'Unknown';
                        final email = studentData['email'] ?? 'No email';
                        final profileImageUrl = studentData['profileImageUrl'];
                        final job = studentData['job'] ?? 'No department';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: profileImageUrl != null
                                  ? NetworkImage(profileImageUrl)
                                  : const AssetImage('assets/admin_default.jpg')
                                      as ImageProvider,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$job',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => _buildOptionsBottomSheet(studentId),
                                );
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmployeeDetailsPage(
                                    studentId: studentId,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'office_timing',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfficeTimingSettings(),
                  ),
                );
              },
              backgroundColor: Colors.green.shade900,
              child: const Icon(Icons.access_time),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'add_employee',
              onPressed: () {
                // TODO: Implement add employee functionality
                _showSnackBar('Add employee feature coming soon');
              },
              backgroundColor: Colors.green.shade900,
              child: const Icon(Icons.person_add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsBottomSheet(String studentId) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Details'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement edit functionality
              _showSnackBar('Edit feature coming soon');
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement view profile functionality
              _showSnackBar('View profile feature coming soon');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Remove Employee', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(studentId);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Employee'),
        content: const Text('Are you sure you want to remove this employee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore
                    .collection('teachers')
                    .doc(_adminId)
                    .collection('friends')
                    .doc(studentId)
                    .delete();
                _showSnackBar('Employee removed successfully');
              } catch (e) {
                _showSnackBar('Error removing employee: $e');
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 