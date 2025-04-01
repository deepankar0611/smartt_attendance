import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'addgroup.dart';
import 'employee_list_screen.dart';
import 'backup_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return const DashboardHome();
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isMenuOpen = false;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;
  String? _profileImageUrl;
  bool _isImageLoading = true;

  // Data for dashboard sections
  Map<String, dynamic> _summaryData = {
    'totalEmployees': 0,
    'totalEmployeesChange': 0.0, // Percentage change for total employees
    'presentToday': 0,
    'presentTodayChange': 0.0, // Percentage change for present today
    'onLeave': 0,
    'activeProjects': 0,
  };
  List<Map<String, dynamic>> _attendanceData = [];
  Map<String, double> _teamPerformance = {};
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _topPerformers = [];
  bool _isLoading = true;

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

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Fetch summary data
      await _fetchSummaryData();

      // Fetch attendance data for the chart
      await _fetchAttendanceData();

      // Fetch team performance data
      await _fetchTeamPerformance();

      // Fetch project data
      await _fetchProjects();

      // Fetch recent activities
      await _fetchActivities();

      // Fetch top performers
      await _fetchTopPerformers();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSummaryData() async {
    // Fetch total friends (instead of total employees)
    QuerySnapshot friendsSnapshot = await _firestore
        .collection('teachers')
        .doc(_userId)
        .collection('friends')
        .get();
    int totalFriends = friendsSnapshot.docs.length;
    print('Total friends fetched: $totalFriends'); // Debug log

    // Fetch historical friend count for the previous month
    double totalFriendsChange = 0.0;
    DateTime now = DateTime.now();
    DateTime firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfPreviousMonth = firstDayOfCurrentMonth.subtract(Duration(days: 1));
    QuerySnapshot previousFriendsSnapshot = await _firestore
        .collection('teachers')
        .doc(_userId)
        .collection('friendHistory') // Assuming a subcollection to store historical friend counts
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfPreviousMonth))
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (previousFriendsSnapshot.docs.isNotEmpty) {
      int previousFriendsCount = previousFriendsSnapshot.docs.first.get('count') ?? 0;
      if (previousFriendsCount > 0) {
        totalFriendsChange = ((totalFriends - previousFriendsCount) / previousFriendsCount) * 100;
      }
    }

    // Fetch friend UIDs to check their attendance
    List<String> friendUids = friendsSnapshot.docs
        .map((doc) => doc.get('friendId') as String)
        .toList();
    print('Friend UIDs: $friendUids'); // Debug log

    // Fetch present today and on leave
    int presentToday = 0;
    int onLeave = 0;
    DateTime today = DateTime(now.year, now.month, now.day);

    for (String friendUid in friendUids) {
      DocumentSnapshot studentDoc = await _firestore.collection('students').doc(friendUid).get();
      if (studentDoc.exists) {
        var data = studentDoc.data() as Map<String, dynamic>;
        print('Student data for $friendUid: $data'); // Debug log

        // Check if the friend checked in today (only based on checkInTime)
        if (data.containsKey('checkInTime') && data['checkInTime'] != null) {
          Timestamp checkInTimestamp = data['checkInTime'] as Timestamp;
          DateTime checkInDate = checkInTimestamp.toDate();
          DateTime checkInDateOnly = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
          print('Check-in date for $friendUid: $checkInDateOnly, Today: $today'); // Debug log
          if (checkInDateOnly == today) {
            presentToday++;
          }
        }

        // Check leave status
        if (data['leaveStatus'] == 'On Leave') {
          onLeave++;
        }
      } else {
        print('No student document found for $friendUid');
      }
    }

    // Fetch historical present count for yesterday
    double presentTodayChange = 0.0;
    DateTime yesterday = now.subtract(Duration(days: 1));
    QuerySnapshot yesterdayAttendanceSnapshot = await _firestore
        .collection('attendanceRecords')
        .where('date', isEqualTo: Timestamp.fromDate(DateTime(yesterday.year, yesterday.month, yesterday.day)))
        .limit(1)
        .get();

    if (yesterdayAttendanceSnapshot.docs.isNotEmpty) {
      int yesterdayPresent = yesterdayAttendanceSnapshot.docs.first.get('present') ?? 0;
      if (yesterdayPresent > 0) {
        presentTodayChange = ((presentToday - yesterdayPresent) / yesterdayPresent) * 100;
      }
    }

    // Fetch active projects
    QuerySnapshot projectsSnapshot = await _firestore.collection('projects').get();
    int activeProjects = projectsSnapshot.docs.length;

    setState(() {
      _summaryData = {
        'totalEmployees': totalFriends,
        'totalEmployeesChange': totalFriendsChange,
        'presentToday': presentToday,
        'presentTodayChange': presentTodayChange,
        'onLeave': onLeave,
        'activeProjects': activeProjects,
      };
    });
    print('Summary data updated: $_summaryData'); // Debug log
  }

  Future<void> _fetchAttendanceData() async {
    QuerySnapshot attendanceSnapshot = await _firestore
        .collection('attendanceRecords')
        .orderBy('date', descending: true)
        .limit(7)
        .get();

    List<Map<String, dynamic>> attendanceData = [];
    for (var doc in attendanceSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      attendanceData.add({
        'present': (data['present'] ?? 0).toDouble(),
        'late': (data['late'] ?? 0).toDouble(),
        'absent': (data['absent'] ?? 0).toDouble(),
      });
    }

    setState(() {
      _attendanceData = attendanceData;
    });
  }

  Future<void> _fetchTeamPerformance() async {
    QuerySnapshot studentsSnapshot = await _firestore.collection('students').get();
    Map<String, List<double>> teamScores = {};

    for (var doc in studentsSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String job = data['job'] ?? 'Student';
      double performanceScore = (data['performanceScore'] ?? 0).toDouble();

      String department = _mapJobToDepartment(job);
      if (!teamScores.containsKey(department)) {
        teamScores[department] = [];
      }
      teamScores[department]!.add(performanceScore);
    }

    Map<String, double> performance = {};
    teamScores.forEach((team, scores) {
      double avg = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0;
      performance[team] = avg;
    });

    setState(() {
      _teamPerformance = performance;
    });
  }

  Future<void> _fetchProjects() async {
    QuerySnapshot projectsSnapshot = await _firestore.collection('projects').get();
    List<Map<String, dynamic>> projects = projectsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        'name': data['name'] ?? 'Unknown',
        'team': data['team'] ?? 'Unknown',
        'deadline': DateFormat('dd MMM').format((data['deadline'] as Timestamp).toDate()),
        'progress': (data['progress'] ?? 0).toDouble(),
        'color': _getTeamColor(data['team']),
      };
    }).toList();

    setState(() {
      _projects = projects;
    });
  }

  Future<void> _fetchActivities() async {
    QuerySnapshot activitiesSnapshot = await _firestore
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    List<Map<String, dynamic>> activities = activitiesSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        'user': data['user'] ?? 'Unknown',
        'action': data['action'] ?? 'Unknown',
        'time': _formatTimestamp(data['timestamp']),
        'avatar': data['avatar'] ?? 'https://i.pravatar.cc/150',
      };
    }).toList();

    setState(() {
      _activities = activities;
    });
  }

  Future<void> _fetchTopPerformers() async {
    QuerySnapshot performersSnapshot = await _firestore
        .collection('students')
        .orderBy('performanceScore', descending: true)
        .limit(4)
        .get();

    List<Map<String, dynamic>> performers = performersSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        'name': data['name'] ?? 'Unknown',
        'position': data['job'] ?? 'Student',
        'hours': data['hoursWorked'] ?? 0,
        'progress': (data['performanceScore'] ?? 0) / 100,
        'avatar': 'https://i.pravatar.cc/150?img=${doc.id.hashCode % 10}',
      };
    }).toList();

    setState(() {
      _topPerformers = performers;
    });
  }

  String _mapJobToDepartment(String job) {
    switch (job.toLowerCase()) {
      case 'software engineer':
        return 'Development';
      case 'designer':
        return 'Design';
      case 'data scientist':
        return 'Data Science';
      case 'sales representative':
        return 'Sales';
      case 'customer support':
        return 'Customer Support';
      case 'finance manager':
        return 'Finance';
      case 'hr manager':
        return 'HR';
      case 'marketing specialist':
        return 'Marketing';
      default:
        return 'Others';
    }
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

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('dd MMM').format(dateTime);
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      if (_userId.isEmpty) return;

      final teacherDoc = await _firestore.collection('teachers').doc(_userId).get();
      if (teacherDoc.exists) {
        setState(() {
          _profileImageUrl = teacherDoc.data()?['profileImageUrl'];
          _isImageLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
      setState(() => _isImageLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
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
          child: _isImageLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : CircleAvatar(
                  radius: 16,
                  backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!)
                      : const NetworkImage('https://i.pravatar.cc/100'),
                  onBackgroundImageError: (e, s) {
                    print('Error loading profile image: $e');
                  },
                ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.white,
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SummaryCards(summaryData: _summaryData),
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
                          const Text(
                            'Attendance Overview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<String>(
                            value: 'This Month',
                            items: ['This Week', 'This Month', 'Last 3 Months', 'This Year']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: AttendanceChart(attendanceData: _attendanceData),
                      ),
                    ],
                  ),
                ),
              ),
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
                          const Text(
                            'Team Performance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: TeamPerformanceChart(teamPerformance: _teamPerformance),
                      ),
                    ],
                  ),
                ),
              ),
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
                          const Text(
                            'Project Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add', style: TextStyle(fontSize: 12)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ProjectStatusList(projects: _projects),
                    ],
                  ),
                ),
              ),
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
                          const Text(
                            'Recent Activities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            child: const Text('View All', style: TextStyle(fontSize: 12)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ActivityList(activities: _activities),
                    ],
                  ),
                ),
              ),
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
                          const Text(
                            'Top Performers',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<String>(
                            value: 'This Month',
                            items: ['This Week', 'This Month', 'This Quarter']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TopPerformersList(performers: _topPerformers),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: _isMenuOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Column(
              children: [
                FloatingActionButton.extended(
                  onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeListScreen()),
                  );
                    _toggleMenu();
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  label: const Text('Department'),
                  icon: const Icon(Icons.business),
                  elevation: 4,
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectAssignmentScreen()),
                  );
                    _toggleMenu();
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  label: const Text('Group'),
                  icon: const Icon(Icons.group),
                  elevation: 4,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: const Color(0xff006600),
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animationController,
              color: Colors.white,
            ),
          ),
        ],
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
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmployeeListScreen()),
            );
          },
          child: _buildSummaryCard(
            context,
            title: 'Total Employees',
            value: summaryData['totalEmployees'].toString(),
            changePercentage: summaryData['totalEmployeesChange'],
            iconData: Icons.people,
            iconColor: Colors.blue,
          ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  changePercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: changePercentage >= 0 ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${changePercentage.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: changePercentage >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'last ${title == 'Present Today' ? 'day' : 'month'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> attendanceData;

  const AttendanceChart({Key? key, required this.attendanceData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final labels = ['1', '5', '10', '15', '20', '25', '30'];
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()}%',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: attendanceData.length - 1,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(attendanceData.length, (index) {
              return FlSpot(index.toDouble(), attendanceData[index]['present']);
            }),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: List.generate(attendanceData.length, (index) {
              return FlSpot(index.toDouble(), attendanceData[index]['late']);
            }),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: List.generate(attendanceData.length, (index) {
              return FlSpot(index.toDouble(), attendanceData[index]['absent']);
            }),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final color = barSpot.bar.color;
                String status;
                if (color == Colors.green) {
                  status = 'Present';
                } else if (color == Colors.orange) {
                  status = 'Late';
                } else {
                  status = 'Absent';
                }
                return LineTooltipItem(
                  '$status: ${barSpot.y.toInt()}%',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class TeamPerformanceChart extends StatelessWidget {
  final Map<String, double> teamPerformance;

  const TeamPerformanceChart({Key? key, required this.teamPerformance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> teams = teamPerformance.keys.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${teams[groupIndex]}: ${rod.toY.toInt()}%',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < teams.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      teams[index].substring(0, teams[index].length > 4 ? 4 : teams[index].length),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()}%',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: List.generate(teams.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: teamPerformance[teams[index]]!,
                color: _getTeamColor(teams[index]),
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Color _getTeamColor(String team) {
    switch (team.toLowerCase()) {
      case 'development':
        return Colors.blue;
      case 'design':
        return Colors.purple;
      case 'qa':
        return Colors.green;
      case 'marketing':
        return Colors.orange;
      case 'sales':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class ProjectStatusList extends StatelessWidget {
  final List<Map<String, dynamic>> projects;

  const ProjectStatusList({Key? key, required this.projects}) : super(key: key);

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
                    Text(
                      project['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project['team'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Deadline: ${project['deadline']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
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
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}

class ActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const ActivityList({Key? key, required this.activities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: NetworkImage(activity['avatar'] as String),
          ),
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: activity['user'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' '),
                TextSpan(text: activity['action'] as String),
              ],
            ),
          ),
          subtitle: Text(
            activity['time'] as String,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        );
      },
    );
  }
}

class TopPerformersList extends StatelessWidget {
  final List<Map<String, dynamic>> performers;

  const TopPerformersList({Key? key, required this.performers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: performers.length,
      itemBuilder: (context, index) {
        final performer = performers[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(performer['avatar'] as String),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      performer['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      performer['position'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${performer['hours']} hrs',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}