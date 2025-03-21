import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class EmployeeAttendanceScreen extends StatefulWidget {
  @override
  _EmployeeAttendanceScreenState createState() => _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> with SingleTickerProviderStateMixin {
  bool _showDepartments = false;
  String _selectedDepartment = 'Select Department';
  int _currentTabIndex = 0;
  TabController? _tabController;

  final List<String> _departments = [
    'All Departments',
    'Engineering',
    'Design',
    'Product',
    'Marketing',
    'Human Resources',
    'Finance',
    'Customer Support'
  ];

  final List<Map<String, dynamic>> _departmentIcons = [
    {'icon': Icons.business, 'color': Colors.blue},
    {'icon': Icons.code, 'color': Colors.indigo},
    {'icon': Icons.brush, 'color': Colors.purple},
    {'icon': Icons.inventory_2, 'color': Colors.green},
    {'icon': Icons.campaign, 'color': Colors.orange},
    {'icon': Icons.people, 'color': Colors.red},
    {'icon': Icons.account_balance, 'color': Colors.teal},
    {'icon': Icons.headset_mic, 'color': Colors.amber},
  ];

  // Three different data sets for each tab
  final List<List<Map<String, dynamic>>> _tabData = [
    // Logged In
    [
      {
        'name': 'Brett Johnson',
        'position': 'UI Designer',
        'status': 'Regular',
        'loginTime': '9:18 AM',
        'logoutTime': '-',
        'attendance': 'Late',
        'avatar': Colors.blue[200],
      },
      {
        'name': 'Brett Johnson',
        'position': 'Software Engineer',
        'status': 'Regular',
        'loginTime': '9:15 AM',
        'logoutTime': '-',
        'attendance': 'Late',
        'avatar': Colors.purple[200],
      },
      {
        'name': 'Rhodes Peter',
        'position': 'Project Manager',
        'status': 'Regular',
        'loginTime': '9:05 AM',
        'logoutTime': '-',
        'attendance': 'Late',
        'avatar': Colors.orange[200],
      },
      {
        'name': 'Jeff Jane',
        'position': 'HR Head',
        'status': 'Regular',
        'loginTime': '9:00 AM',
        'logoutTime': '-',
        'attendance': 'Ontime',
        'avatar': Colors.green[200],
      },
      {
        'name': 'Emily Butler',
        'position': 'Data Scientist',
        'status': 'Vendor',
        'loginTime': '8:55 AM',
        'logoutTime': '-',
        'attendance': 'Ontime',
        'avatar': Colors.red[200],
      }
    ],
    // On Time
    [
      {
        'name': 'Jeff Jane',
        'position': 'HR Head',
        'status': 'Regular',
        'loginTime': '9:00 AM',
        'logoutTime': '-',
        'attendance': 'Ontime',
        'avatar': Colors.green[200],
      },
      {
        'name': 'Emily Butler',
        'position': 'Data Scientist',
        'status': 'Vendor',
        'loginTime': '8:55 AM',
        'logoutTime': '-',
        'attendance': 'Ontime',
        'avatar': Colors.red[200],
      },
      {
        'name': 'Michael Smith',
        'position': 'Frontend Developer',
        'status': 'Regular',
        'loginTime': '8:50 AM',
        'logoutTime': '-',
        'attendance': 'Ontime',
        'avatar': Colors.teal[200],
      },
      {
        'name': 'Sarah Wilson',
        'position': 'UX Researcher',
        'status': 'Regular',
        'loginTime': '8:45 AM',
        'logoutTime': '-',
        'attendance': 'Ontime',
        'avatar': Colors.amber[200],
      }
    ],
    // Late
    [
      {
        'name': 'Brett Johnson',
        'position': 'UI Designer',
        'status': 'Regular',
        'loginTime': '9:18 AM',
        'logoutTime': '-',
        'attendance': 'Late',
        'avatar': Colors.blue[200],
      },
      {
        'name': 'Brett Johnson',
        'position': 'Software Engineer',
        'status': 'Regular',
        'loginTime': '9:15 AM',
        'logoutTime': '-',
        'attendance': 'Late',
        'avatar': Colors.purple[200],
      },
      {
        'name': 'Rhodes Peter',
        'position': 'Project Manager',
        'status': 'Regular',
        'loginTime': '9:05 AM',
        'logoutTime': '-',
        'attendance': 'Late',
        'avatar': Colors.orange[200],
      },
    ],
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController!.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showDepartmentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business,
                          color: Colors.grey[700],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Select Department',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(thickness: 1, height: 1),

                  // Department attendance cards grid
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildDepartmentCard(
                          icon: Icons.design_services,
                          iconColor: Colors.blue,
                          title: 'Design',
                          total: 23,
                          onTime: 18,
                          late: 4,
                          leave: 1,
                        ),
                        _buildDepartmentCard(
                          icon: Icons.code,
                          iconColor: Colors.purple,
                          title: 'Development',
                          total: 60,
                          onTime: 40,
                          late: 18,
                          leave: 2,
                        ),
                        _buildDepartmentCard(
                          icon: Icons.analytics,
                          iconColor: Colors.green,
                          title: 'Data Science',
                          total: 28,
                          onTime: 20,
                          late: 8,
                          leave: 0,
                        ),
                        _buildDepartmentCard(
                          icon: Icons.people,
                          iconColor: Colors.orange,
                          title: 'Sales',
                          total: 12,
                          onTime: 7,
                          late: 5,
                          leave: 0,
                        ),
                      ],
                    ),
                  ),

                  Divider(),

                  // Department list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: _departments.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedDepartment == _departments[index];
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? _departmentIcons[index]['color'].withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: _departmentIcons[index]['color'].withOpacity(0.2),
                              child: Icon(
                                _departmentIcons[index]['icon'],
                                color: _departmentIcons[index]['color'],
                                size: 20,
                              ),
                            ),
                            title: Text(
                              _departments[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: _departmentIcons[index]['color'])
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedDepartment = _departments[index];
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Helper method to build department attendance card
  Widget _buildDepartmentCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int total,
    required int onTime,
    required int late,
    required int leave,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle card tap
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row with total count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          total.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    // Attendance breakdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildAttendanceItem('On-time', onTime.toString()),
                        _buildAttendanceItem('Late', late.toString()),
                        _buildAttendanceItem('Leave', leave > 0 ? leave.toString() : '--'),
                      ],
                    ),
                  ],
                ),

                // Department name with icon
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: iconColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper method for attendance breakdown items
  Widget _buildAttendanceItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          Text(
            '$label',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

// Add this helper function
  int _getEmployeeCount(int departmentIndex) {
    // Replace with actual logic to get employee count per department
    return 5 + departmentIndex * 3; // Dummy count for demonstration
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Department Selector
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: InkWell(

                    onTap: _showDepartmentSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                          SizedBox(width: 8),
                          Text(
                            _selectedDepartment,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tabs
                Container(
                  margin: EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white!,
                        width: 0,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.blue[700],
                    indicatorWeight: 3,
                    labelColor: Colors.blue[700],
                    unselectedLabelColor: Colors.grey[500],
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, size: 16),
                            SizedBox(width: 4),
                            Text('Logged in'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer, size: 16),
                            SizedBox(width: 4),
                            Text('On Time (80)'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule, size: 16),
                            SizedBox(width: 4),
                            Text('Late (30)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search employees',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'View all employees',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Employee List - TabBarView with different content for each tab
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [0, 1, 2].map((tabIndex) {
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _tabData[tabIndex].length,
                        itemBuilder: (context, index) {
                          final employee = _tabData[tabIndex][index];
                          final bool isLate = employee['attendance'] == 'Late';

                          return Card(
                            color: Colors.white,
                            shadowColor:  Colors.black26,

                            elevation: 5,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[100]!),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: employee['avatar'],
                                    child: Text(
                                      employee['name'].substring(0, 1),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),

                                  // Employee Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              _getPositionIcon(employee['position']),
                                              size: 14,
                                              color: Colors.black,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '${employee['position']} | ${employee['status']}',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.login,
                                              size: 14,
                                              color: Colors.black54,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Login - ${employee['loginTime']}',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.logout,
                                              size: 14,
                                              color: Colors.black54,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Logout - ${employee['logoutTime']}',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status Indicator
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isLate
                                              ? Colors.red[50]
                                              : Colors.green[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isLate
                                                ? Colors.red[300]!
                                                : Colors.green[300]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isLate ? Icons.schedule : Icons.check_circle,
                                              size: 12,
                                              color: isLate
                                                  ? Colors.red[400]
                                                  : Colors.green[400],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              employee['attendance'],
                                              style: TextStyle(
                                                color: isLate
                                                    ? Colors.red[400]
                                                    : Colors.green[400],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Detail button
                                      if (index == 1 || (tabIndex == 1 && index == 0) || (tabIndex == 2 && index == 0))
                                        Padding(
                                          padding: EdgeInsets.only(top: 12),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.08),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey[500],
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPositionIcon(String position) {
    switch (position.toLowerCase()) {
      case 'ui designer':
        return Icons.brush;
      case 'software engineer':
        return Icons.code;
      case 'project manager':
        return Icons.assignment;
      case 'hr head':
        return Icons.people;
      case 'data scientist':
        return Icons.analytics;
      case 'frontend developer':
        return Icons.web;
      case 'ux researcher':
        return Icons.search;
      default:
        return Icons.work;
    }
  }
}