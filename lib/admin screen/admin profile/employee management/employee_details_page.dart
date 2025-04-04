import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../utils/attendance_utils.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final String studentId;

  const EmployeeDetailsPage({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  _EmployeeDetailsPageState createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _adminId;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _adminId = _auth.currentUser?.uid ?? '';
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('students').doc(widget.studentId).snapshots(),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Student data not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red[700],
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
          final job = studentData['job'] ?? 'No job';
          final mobile = studentData['mobile'] ?? 'No mobile';
          final location = studentData['location'] ?? 'No location';

          return NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  backgroundColor: Colors.green.shade900,
                  expandedHeight: 0,
                  floating: false,
                  pinned: true,
                  title: const Text(
                    'Employee Details',
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
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildProfileHeader(name, profileImageUrl),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildInfoCard(
                          title: 'Personal Information',
                          children: [
                            _buildInfoRow(Icons.email, 'Email', email),
                            _buildInfoRow(Icons.phone, 'Mobile', mobile),
                            _buildInfoRow(Icons.location_on, 'Location', location),
                            _buildInfoRow(Icons.work, 'Job', job),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.green.shade900,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.green.shade900,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.access_time),
                          text: 'Attendance',
                        ),
                        Tab(
                          icon: Icon(Icons.assignment),
                          text: 'Projects',
                        ),
                        Tab(
                          icon: Icon(Icons.event_busy),
                          text: 'Leaves',
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildAttendanceSection(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildProjectSection(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildLeaveHistorySection(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String? profileImageUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.green.shade900,
            Colors.green.shade800,
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl)
                : const AssetImage('assets/admin_default.jpg') as ImageProvider,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.green.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to full attendance history
                  _showSnackBar('Full attendance history coming soon');
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('students')
                .doc(widget.studentId)
                .collection('attendance')
                .orderBy('checkInTime', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                );
              }

              final attendanceRecords = snapshot.data!.docs;
              if (attendanceRecords.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No attendance records found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = attendanceRecords[index].data() as Map<String, dynamic>;
                  final checkInTime = (record['checkInTime'] as Timestamp).toDate();
                  final checkOutTime = record['checkOutTime'] != null
                      ? (record['checkOutTime'] as Timestamp).toDate()
                      : null;

                  return FutureBuilder<String>(
                    future: AttendanceUtils.calculateAttendanceStatus(
                      checkInTime,
                      checkOutTime,
                    ),
                    builder: (context, statusSnapshot) {
                      final status = statusSnapshot.data ?? AttendanceStatus.onTime;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getStatusIcon(status),
                                size: 20,
                                color: _getStatusColor(status),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(checkInTime),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Check-in: ${DateFormat('hh:mm a').format(checkInTime)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (checkOutTime != null)
                                    Text(
                                      'Check-out: ${DateFormat('hh:mm a').format(checkOutTime)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AttendanceStatus.onTime:
        return Colors.green.shade700;
      case AttendanceStatus.late:
        return Colors.orange.shade700;
      case AttendanceStatus.earlyCheckout:
        return Colors.red.shade700;
      case AttendanceStatus.absent:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AttendanceStatus.onTime:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.warning;
      case AttendanceStatus.earlyCheckout:
        return Icons.exit_to_app;
      case AttendanceStatus.absent:
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  Widget _buildProjectSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to full project list
                  _showSnackBar('Full project list coming soon');
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('projects')
                .where('employeeUids', arrayContains: widget.studentId)
                .orderBy('createdAt', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                );
              }

              final projects = snapshot.data!.docs;
              if (projects.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No projects assigned',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index].data() as Map<String, dynamic>;
                  final title = project['name'] ?? 'Untitled Project';
                  final status = project['status'] ?? 'In Progress';
                  final dueDate = project['deadline'] != null
                      ? (project['deadline'] as Timestamp).toDate()
                      : null;
                  final description = project['description'] ?? 'No description provided';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.assignment,
                                size: 20,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'Completed'
                                    ? Colors.green.shade50
                                    : status == 'In Progress'
                                        ? Colors.orange.shade50
                                        : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: status == 'Completed'
                                      ? Colors.green.shade700
                                      : status == 'In Progress'
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (dueDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveHistorySection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leave History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to full leave history
                  _showSnackBar('Full leave history coming soon');
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('students')
                .doc(widget.studentId)
                .collection('leaves')
                .orderBy('startDate', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                );
              }

              final leaves = snapshot.data!.docs;
              if (leaves.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No leave records found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leaves.length,
                itemBuilder: (context, index) {
                  final leave = leaves[index].data() as Map<String, dynamic>;
                  final startDate = (leave['startDate'] as Timestamp).toDate();
                  final endDate = (leave['endDate'] as Timestamp).toDate();
                  final type = leave['type'] ?? 'Leave';
                  final status = leave['status'] ?? 'Pending';
                  final reason = leave['reason'] ?? 'No reason provided';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_busy,
                                size: 20,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'Approved'
                                    ? Colors.green.shade50
                                    : status == 'Pending'
                                        ? Colors.orange.shade50
                                        : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: status == 'Approved'
                                      ? Colors.green.shade700
                                      : status == 'Pending'
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
} 