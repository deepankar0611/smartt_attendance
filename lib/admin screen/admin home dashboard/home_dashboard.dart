import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smartt_attendance/admin%20screen/admin%20home%20dashboard/project_list_screen.dart';
import '../../utils/attendance_utils.dart';
import 'package:smartt_attendance/providers/admin_dashboard_provider.dart';

import '../admin profile/employee management/employee_management_page.dart';
import 'assign_project.dart';
import 'analyzer_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDashboardProvider()..initialize(),
      child: const DashboardHome(),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _userId = _auth.currentUser?.uid ?? '';
    if (_userId.isEmpty) {
      print('No user is currently signed in.');
    }
    _fetchDashboardData();
    _loadProfileImage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  Future<void> _fetchDashboardData() async {
    try {
      await _fetchSummaryData();
      await _fetchProjects();
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  Future<void> _fetchSummaryData() async {
    try {

      // Fetch friends
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('teachers')
          .doc(_userId)
          .collection('friends')
          .get();

      // Calculate total friends change
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
        // Fetch student document
        DocumentSnapshot studentDoc = await _firestore.collection('students').doc(friendUid).get();
        if (studentDoc.exists) {
          var data = studentDoc.data() as Map<String, dynamic>;

          // Check for present today
          if (data.containsKey('checkInTime') && data['checkInTime'] != null) {
            try {
              Timestamp checkInTimestamp = data['checkInTime'] as Timestamp;
              DateTime checkInDate = checkInTimestamp.toDate();
              
              if (DateTime(checkInDate.year, checkInDate.month, checkInDate.day).isAtSameMomentAs(today)) {
                // Get check-out time if exists
                DateTime? checkOutDate;
                if (data.containsKey('checkOutTime') && data['checkOutTime'] != null) {
                  Timestamp checkOutTimestamp = data['checkOutTime'] as Timestamp;
                  checkOutDate = checkOutTimestamp.toDate();
                }

                // Calculate attendance status
                final checkInTime = checkInDate;
                final checkOutTime = checkOutDate;

                final status = await AttendanceUtils.calculateAttendanceStatus(
                  checkInTime,
                  checkOutTime,
                  teacherId: _userId,
                );

                if (status == AttendanceStatus.onTime) {
                  presentToday++;
                } else if (status == AttendanceStatus.late) {
                  // Handle late attendance
                }
              }
            } catch (e) {
              print('Error parsing checkInTime for $friendUid: $e');
            }
          }

          // Fetch leave data
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

      // Calculate present today change
      DateTime yesterday = today.subtract(Duration(days: 1));
      QuerySnapshot yesterdayAttendanceSnapshot = await _firestore
          .collection('attendanceRecords')
          .where('date', isEqualTo: Timestamp.fromDate(yesterday))
          .limit(1)
          .get();

      if (yesterdayAttendanceSnapshot.docs.isNotEmpty) {
        int yesterdayPresent = yesterdayAttendanceSnapshot.docs.first.get('present') ?? 0;
        if (yesterdayPresent > 0) {
        }
      }


      setState(() {
      });
    } catch (e) {
      print('Error fetching summary data: $e');
    }
  }



  Future<void> _fetchProjects() async {
    QuerySnapshot projectsSnapshot = await _firestore.collection('projects').get();
    projectsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        'name': data['name'] ?? 'Unknown',
        'team': data['team'] ?? 'Unknown',
        'deadline': DateFormat('dd MMM').format((data['deadline'] as Timestamp).toDate()),
        'progress': (data['progress'] ?? 0).toDouble(),
        'color': _getTeamColor(data['team']),
      };
    }).toList();

  }

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

  Future<void> _loadProfileImage() async {
    try {
      if (_userId.isEmpty) return;
      final teacherDoc = await _firestore.collection('teachers').doc(_userId).get();
      if (teacherDoc.exists) {
        setState(() {
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff003300), Color(0xff006600)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Consumer<AdminDashboardProvider>(
            builder: (context, provider, _) {
              return provider.isImageLoading
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : CircleAvatar(
                      radius: 16,
                      backgroundImage: provider.profileImageUrl != null && provider.profileImageUrl!.isNotEmpty
                          ? NetworkImage(provider.profileImageUrl!)
                          : const NetworkImage('https://i.pravatar.cc/100'),
                      onBackgroundImageError: (e, s) => print('Error loading profile image: $e'),
                    );
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<AdminDashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.summaryData.isEmpty) {
            return const Center(child: Text('No data available', style: TextStyle(fontSize: 18, color: Colors.grey)));
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SummaryCards(summaryData: provider.summaryData),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shadowColor: Colors.grey.withOpacity(0.2),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Project Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add', style: TextStyle(fontSize: 12)),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectAssignmentScreen())),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ProjectStatusList(projects: provider.projects),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AdminDashboardProvider>(
        builder: (context, provider, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedOpacity(
                opacity: provider.isMenuOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'fab_employee',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeManagementPage()));
                        provider.toggleMenu();
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      label: const Text('Employee List'),
                      icon: const Icon(Icons.business),
                      elevation: 4,
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.extended(
                      heroTag: 'fab_project',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen()));
                        provider.toggleMenu();
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      label: const Text('Project'),
                      icon: const Icon(Icons.group),
                      elevation: 4,
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.extended(
                      heroTag: 'fab_analyzer',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyzerScreen()));
                        provider.toggleMenu();
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      label: const Text('Analyzer'),
                      icon: const Icon(Icons.analytics),
                      elevation: 4,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              FloatingActionButton(
                heroTag: 'fab_menu',
                onPressed: provider.toggleMenu,
                backgroundColor: const Color(0xff006600),
                child: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: AlwaysStoppedAnimation(provider.isMenuOpen ? 1.0 : 0.0),
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SummaryCards extends StatelessWidget {
  final Map<String, dynamic> summaryData;

  const SummaryCards({Key? key, required this.summaryData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          context,
          title: 'Total Employees',
          value: summaryData['totalEmployees'].toString(),
          changePercentage: summaryData['totalEmployeesChange'],
          iconData: Icons.people,
          iconColor: Colors.blue,
        ),
        _buildSummaryCard(
          context,
          title: 'Present Today',
          value: summaryData['presentToday'].toString(),
          changePercentage: summaryData['presentTodayChange'],
          iconData: Icons.check_circle,
          iconColor: Colors.green,
        ),
        _buildSummaryCard(
          context,
          title: 'On Leave',
          value: summaryData['onLeave'].toString(),
          changePercentage: -8.3,
          iconData: Icons.calendar_today,
          iconColor: Colors.orange,
        ),
        _buildSummaryCard(
          context,
          title: 'Active Projects',
          value: summaryData['activeProjects'].toString(),
          changePercentage: 4.1,
          iconData: Icons.work,
          iconColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required String title,
        required String value,
        required double changePercentage,
        required IconData iconData,
        required Color iconColor,
      }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Icon(iconData, color: iconColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(changePercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: changePercentage >= 0 ? Colors.green : Colors.red, size: 14),
                const SizedBox(width: 4),
                Text('${changePercentage.abs().toStringAsFixed(1)}%', style: TextStyle(color: changePercentage >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 4),
                Expanded(child: Text('last ${title == 'Present Today' ? 'day' : 'month'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 10))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectStatusList extends StatelessWidget {
  final List<Map<String, dynamic>> projects;

  const ProjectStatusList({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final project = projects[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(project['team'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Text('Deadline: ${project['deadline']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), const SizedBox(width: 16)]),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: project['progress'] as double,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(project['color'] as Color),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
        );
      },
    );
  }
}