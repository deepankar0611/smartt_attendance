import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart'; // Add this import for DateFormat
import '../utils/attendance_utils.dart';
import 'package:provider/provider.dart';
import '../providers/employee_list_provider.dart';

class EmployeeAttendanceScreen extends StatelessWidget {
  const EmployeeAttendanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmployeeListProvider()..initialize(),
      child: const _EmployeeAttendanceContent(),
    );
  }
}

class _EmployeeAttendanceContent extends StatefulWidget {
  const _EmployeeAttendanceContent({Key? key}) : super(key: key);

  @override
  _EmployeeAttendanceContentState createState() => _EmployeeAttendanceContentState();
}

class _EmployeeAttendanceContentState extends State<_EmployeeAttendanceContent> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showDepartmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<EmployeeListProvider>(
          builder: (context, provider, _) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                int totalAll = provider.jobStats.values.fold(0, (sum, stats) => sum + (stats['total'] as int));
                int onTimeAll = provider.jobStats.values.fold(0, (sum, stats) => sum + (stats['onTime'] as int));
                int lateAll = provider.jobStats.values.fold(0, (sum, stats) => sum + (stats['late'] as int));
                int leaveAll = provider.jobStats.values.fold(0, (sum, stats) => sum + (stats['leave'] as int));

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
                      Container(
                        margin: EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
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
                              provider.selectedDepartment != 'Select Department' ? provider.selectedDepartment : 'Select Department',
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
                      Expanded(
                        child: GridView.count(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16.0),
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildDepartmentCard(
                              context,
                              icon: Icons.corporate_fare,
                              iconColor: Colors.teal,
                              title: 'All Departments',
                              total: totalAll,
                              onTime: onTimeAll,
                              late: lateAll,
                              leave: leaveAll,
                              onTap: () {
                                provider.setSelectedDepartment('All Departments');
                                Navigator.pop(context);
                              },
                            ),
                            ...provider.jobStats.entries.map((entry) {
                              String job = entry.key;
                              Map<String, dynamic> stats = entry.value;
                              Map<String, dynamic> deptDetails = provider.getDepartmentDetails(job);

                              return _buildDepartmentCard(
                                context,
                                icon: deptDetails['icon'],
                                iconColor: deptDetails['iconColor'],
                                title: deptDetails['title'],
                                total: stats['total'],
                                onTime: stats['onTime'],
                                late: stats['late'],
                                leave: stats['leave'],
                                onTap: () {
                                  provider.setSelectedDepartment(deptDetails['title']);
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
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
      },
    );
  }

  Widget _buildDepartmentCard(
    BuildContext context, {
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Container(
                  height: 70,
                  width: 1,
                  color: Colors.grey[200],
                ),
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
            ),
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
      appBar: AppBar(
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
      body: Consumer<EmployeeListProvider>(
        builder: (context, provider, _) {
          return SafeArea(
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
                    InkWell(
                      onTap: () => _showDepartmentSheet(context),
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
                              provider.selectedDepartment,
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
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 18),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.black,
                        indicatorWeight: 2,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey[600],
                        labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                        tabs: [
                          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.login, size: 16), SizedBox(width: 6), Text('Logged In')])),
                          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.table_chart_sharp, size: 16), SizedBox(width: 6), Text('On Time')])),
                          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule, size: 14), SizedBox(width: 6), Text('Late')])),
                        ],
                      ),
                    ),
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
                    Expanded(
                      child: provider.isLoading
                          ? Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEmployeeList(context, provider.loggedInData),
                                _buildEmployeeList(context, provider.onTimeData),
                                _buildEmployeeList(context, provider.lateData),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeList(BuildContext context, List<Map<String, dynamic>> data) {
    return Consumer<EmployeeListProvider>(
      builder: (context, provider, _) {
        // Filter data based on selected department
        List<Map<String, dynamic>> filteredData = data.where((employee) {
          if (provider.selectedDepartment == 'All Departments') {
            return true;
          }
          
          Map<String, dynamic> deptDetails = provider.getDepartmentDetails(employee['position']);
          return deptDetails['title'] == provider.selectedDepartment;
        }).toList();

        if (filteredData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No employees found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try selecting a different department',
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
          padding: EdgeInsets.symmetric(horizontal: 12),
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            final employee = filteredData[index];
            final bool isLate = employee['attendance'] == 'Late';

            return Card(
              color: Colors.white,
              shadowColor: Colors.black26,
              elevation: 5,
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[100]!)),
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
                      Container(
                        width: 48,
                        height: 58,
                        decoration: BoxDecoration(
                          color: employee['avatar'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            employee['name']?.substring(0, 1) ?? '?',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(employee['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(provider.getPositionIcon(employee['position']), size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text('${employee['position']} | ${employee['status']}', style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Check-in: ${employee['checkInLocation']}',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (employee['checkOutLocation'] != 'Not specified') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_off, size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Check-out: ${employee['checkOutLocation']}',
                                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey[200], thickness: 1, height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.login, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text('In: ${employee['loginTime']}', style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                                  ],
                                ),
                                if (employee['checkOutTime'] != 'Not checked out')
                                  Row(
                                    children: [
                                      Icon(Icons.logout, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text('Out: ${employee['checkOutTime']}', style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                                  employee['attendance'],
                                  style: TextStyle(
                                    color: isLate ? Colors.red[400] : Colors.green[400],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      },
    );
  }
}