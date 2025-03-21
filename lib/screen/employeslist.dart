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
                          _selectedDepartment != null ? _selectedDepartment! : 'Select Department',
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

                  // Department attendance cards grid - expanded with more cards
                  Expanded(
                    child: GridView.count(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0),
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        // All Departments Card
                        _buildDepartmentCard(
                          icon: Icons.corporate_fare,
                          iconColor: Colors.teal,
                          title: 'All Departments',
                          total: 150,
                          onTime: 108,
                          late: 35,
                          leave: 7,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = 'All Departments';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        // Original cards
                        _buildDepartmentCard(
                          icon: Icons.design_services,
                          iconColor: Colors.blue,
                          title: 'Design',
                          total: 23,
                          onTime: 18,
                          late: 4,
                          leave: 1,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = 'Design';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildDepartmentCard(
                          icon: Icons.code,
                          iconColor: Colors.purple,
                          title: 'Development',
                          total: 60,
                          onTime: 40,
                          late: 18,
                          leave: 2,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = 'Development';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildDepartmentCard(
                          icon: Icons.analytics,
                          iconColor: Colors.green,
                          title: 'Data Science',
                          total: 28,
                          onTime: 20,
                          late: 8,
                          leave: 0,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = 'Data Science';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildDepartmentCard(
                          icon: Icons.people,
                          iconColor: Colors.orange,
                          title: 'Sales',
                          total: 12,
                          onTime: 7,
                          late: 5,
                          leave: 0,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = 'Sales';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        // Additional cards from the list
                        _buildDepartmentCard(
                          icon: Icons.support_agent,
                          iconColor: Colors.red,
                          title: 'Customer Support',
                          total: 18,
                          onTime: 15,
                          late: 2,
                          leave: 1,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = 'Customer Support';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildDepartmentCard(
                          icon: Icons.money,
                          iconColor: Colors.green,
                          title: 'Finance',
                          total: 9,
                          onTime: 8,
                          late: 1,
                          leave: 0,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = 'Finance';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildDepartmentCard(
                          icon: Icons.person,
                          iconColor: Colors.deepPurple,
                          title: 'HR',
                          total: 7,
                          onTime: 7,
                          late: 0,
                          leave: 0,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = 'HR';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildDepartmentCard(
                          icon: Icons.shopping_cart,
                          iconColor: Colors.amber,
                          title: 'Marketing',
                          total: 14,
                          onTime: 10,
                          late: 3,
                          leave: 1,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = 'Marketing';
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
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

// Updated _buildDepartmentCard to include onTap functionality
  Widget _buildDepartmentCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int total,
    required int onTime,
    required int late,
    required int leave,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        padding: EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top section with Total and status metrics
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total number (left side, large)
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$total',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical divider between Total and status metrics
                Container(
                  height: 70,
                  width: 1,
                  color: Colors.grey[200],
                ),

                // Status metrics (right side)
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // On-time
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'On-time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Spacer(),
                            Text(
                              onTime.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 8, thickness: 0.5, color: Colors.grey[200]),

                        // Late
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Late',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Spacer(),
                            Text(
                              late.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 8, thickness: 0.5, color: Colors.grey[200]),

                        // Leave
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Leave',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Spacer(),
                            Text(
                              leave > 0 ? leave.toString().padLeft(2, '0') : '--',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Horizontal divider before department info
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
            ),
            // Department name and icon at bottom
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
                SizedBox(width: 8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:  AppBar(
        title: const Text('Departments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
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
      ),
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Department Selector
                InkWell(
                  onTap: _showDepartmentSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[100]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge,
                          size: 18,
                          color: Colors.black,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _selectedDepartment,
                          style: TextStyle(
                            fontSize: 17,
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
                    indicatorColor: Colors.black, // Simple, bold indicator
                    indicatorWeight: 2, // Thinner for minimalism
                    labelColor: Colors.black, // Neutral, minimalist color
                    unselectedLabelColor: Colors.grey[600], // Soft grey for contrast
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login, size: 19), // Smaller icon
                            const SizedBox(width: 6), // Tight spacing
                            const Text('Logged In'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.table_chart_sharp, size: 16),
                            const SizedBox(width: 6),
                            const Text('On Time'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 14),
                            const SizedBox(width: 6),
                            const Text('Late (30)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return ScaleTransition(scale: animation, child: child);
                                },
                                child: Icon(
                                  Icons.search,
                                  key: ValueKey('searchIcon'),
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 400),
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: child,
                                  );
                                },
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search employees...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onChanged: (value) {
                                    // Add your search functionality here
                                  },
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                  cursorColor: Colors.blue[700],
                                  cursorWidth: 1.5,
                                  cursorRadius: Radius.circular(2),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                        ),
                      ),
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
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar Section
                                    Container(
                                      width: 48, // 2 * radius to match the original CircleAvatar size
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: employee['avatar'] ?? Colors.grey[400],
                                        borderRadius: BorderRadius.circular(8), // Optional: adjust for rounded corners, set to 0 for sharp edges
                                      ),
                                      child: Center(
                                        child: Text(
                                          employee['name']?.substring(0, 1) ?? '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Employee Information Section
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Name
                                          Text(
                                            employee['name'] ?? 'Unknown Employee',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Position and Status
                                          Row(
                                            children: [
                                              Icon(
                                                _getPositionIcon(employee['position']),
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${employee['position'] ?? 'N/A'} | ${employee['status'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Location
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 12,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Location: ${employee['location'] ?? 'Not specified'}',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Divider
                                          Divider(
                                            color: Colors.grey[200],
                                            thickness: 1,
                                            height: 5,
                                          ),

                                          // Login Info
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.login,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Login: ${employee['loginTime'] ?? 'Not recorded'}',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Logout Info
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.logout,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Logout: ${employee['logoutTime'] ?? 'Not recorded'}',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status Indicator Section
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isLate ? Colors.red[50] : Colors.green[50],
                                            borderRadius: BorderRadius.circular(19),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isLate ? Icons.schedule : Icons.check_circle,
                                                size: 14,
                                                color: isLate ? Colors.red[400] : Colors.green[400],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                employee['attendance'] ?? 'Unknown',
                                                style: TextStyle(
                                                  color: isLate ? Colors.red[400] : Colors.green[400],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Late Time Display (only shown if isLate is true)
                                        if (isLate)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              'Late by ${employee['lateDuration'] ?? 'N/A'}',
                                              style: TextStyle(
                                                color: Colors.red[400],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
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