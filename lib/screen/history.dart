import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:table_calendar/table_calendar.dart'; // Added missing import

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  _AttendanceHistoryScreenState createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> with TickerProviderStateMixin {
  DateTime selectedDate = DateTime(2022, 10, 26);
  DateTime currentMonth = DateTime(2022, 10);
  late TabController _tabController;
  bool isListView = true;

  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> attendanceData = [
    // Attendance data remains unchanged
    {
      'date': DateTime(2022, 10, 3),
      'checkIn': '08:15',
      'checkOut': '17:30',
      'totalHours': '9h 15m',
      'location': 'Main Office',
      'status': 'On Time',
      'notes': 'Team meeting at 10 AM',
      'breaks': [{'start': '12:00', 'end': '13:00', 'duration': '1h 0m'}]
    },
    // ... rest of the attendance data ...
  ];

  Map<String, dynamic> getMonthlyStats() {
    final filteredData = _filterAttendanceByMonth();

    if (filteredData.isEmpty) {
      return {
        'workdays': 0,
        'totalHours': '0h 0m',
        'avgHours': '0h 0m',
        'onTime': 0,
        'late': 0,
      };
    }

    int onTime = 0;
    int late = 0;
    int totalMinutes = 0;

    for (var record in filteredData) {
      if (record['status'] == 'On Time' || record['status'] == 'Early') {
        onTime++;
      } else if (record['status'] == 'Late') {
        late++;
      }

      String hoursStr = record['totalHours'];
      List<String> parts = hoursStr.split('h ');
      if (parts.length == 2) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1].replaceAll('m', ''));
        totalMinutes += (hours * 60) + minutes;
      }
    }

    int avgMinutes = (totalMinutes / filteredData.length).round();
    String avgHours = '${(avgMinutes ~/ 60)}h ${avgMinutes % 60}m';
    String totalHoursFormatted = '${(totalMinutes ~/ 60)}h ${totalMinutes % 60}m';

    return {
      'workdays': filteredData.length,
      'totalHours': totalHoursFormatted,
      'avgHours': avgHours,
      'onTime': onTime,
      'late': late,
    };
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
      _animationController.reset();
      _animationController.forward();
    });
  }

  List<Map<String, dynamic>> _filterAttendanceByMonth() {
    return attendanceData.where((record) {
      DateTime recordDate = record['date'] as DateTime;
      return recordDate.year == currentMonth.year && recordDate.month == currentMonth.month;
    }).toList();
  }

  Map<String, dynamic>? _getSelectedDayRecord() {
    for (var record in attendanceData) {
      DateTime recordDate = record['date'] as DateTime;
      if (recordDate.year == selectedDate.year &&
          recordDate.month == selectedDate.month &&
          recordDate.day == selectedDate.day) {
        return record;
      }
    }
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'On Time':
        return Colors.green;
      case 'Late':
        return Colors.orange;
      case 'Early':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAttendance = _filterAttendanceByMonth();
    final stats = getMonthlyStats();
    final selectedDayRecord = _getSelectedDayRecord();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        // Remove the solid backgroundColor
        // backgroundColor: Colors.white,
        elevation: 0,
        // Add shape for rounded bottom corners
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Adjust the radius as needed
          ),
        ),
        // Add gradient background
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff003300),Color(0xff006600),  // Ending green color
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20), // Match this with shape radius
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
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
                            DateFormat('MMMM yyyy').format(currentMonth),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${stats['workdays']} Workdays',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            title: 'Total Hours',
                            value: stats['totalHours'],
                            icon: Icons.access_time,
                          ),
                          _buildStatItem(
                            title: 'Avg Hours/Day',
                            value: stats['avgHours'],
                            icon: Icons.trending_up,
                          ),
                          _buildStatItem(
                            title: 'On Time',
                            value: '${stats['onTime']}/${stats['workdays']}',
                            icon: Icons.check_circle_outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildNavigationButton(Icons.arrow_back_ios_new, _previousMonth),
                        const SizedBox(width: 8),
                        _buildNavigationButton(Icons.arrow_forward_ios, _nextMonth),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => isListView = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isListView ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isListView ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : [],
                              ),
                              child: Icon(
                                Icons.view_list,
                                color: isListView ? Colors.blue[700] : Colors.grey[600],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => isListView = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: !isListView ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: !isListView ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : [],
                              ),
                              child: Icon(
                                Icons.calendar_month,
                                color: !isListView ? Colors.blue[700] : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: isListView
                    ? _buildAttendanceListView(filteredAttendance)
                    : _buildCalendarView(),
              ),

              if (!isListView && selectedDayRecord != null)
                _buildSelectedDayDetail(selectedDayRecord),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({required String title, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.grey[700]),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildAttendanceListView(List<Map<String, dynamic>> attendance) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: attendance.length,
      itemBuilder: (context, index) {
        final record = attendance[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8), // Fixed typo: should be 'bottom'
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,           // Starting color
                  Colors.white,     // Ending color
                ],
              ),
              borderRadius: BorderRadius.circular(12), // Match Card's border radius
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEE, MMM d').format(record['date']),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(record['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record['status'],
                          style: TextStyle(
                            color: _getStatusColor(record['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check In', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Text(record['checkIn'], style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check Out', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Text(record['checkOut'], style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Text(record['totalHours'], style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  if (record['notes'].isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notes: ${record['notes']}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TableCalendar(
        firstDay: DateTime(currentMonth.year - 1),
        lastDay: DateTime(currentMonth.year + 1),
        focusedDay: currentMonth,
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            selectedDate = selectedDay;
            currentMonth = focusedDay;
          });
        },
        calendarFormat: CalendarFormat.month,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.blue[500],
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (attendanceData.any((record) =>
            (record['date'] as DateTime).day == date.day &&
                (record['date'] as DateTime).month == date.month &&
                (record['date'] as DateTime).year == date.year)) {
              return Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetail(Map<String, dynamic> record) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                DateFormat('EEEE, MMMM d').format(record['date']),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(record['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  record['status'],
                  style: TextStyle(
                    color: _getStatusColor(record['status']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Check In', record['checkIn']),
              _buildDetailItem('Check Out', record['checkOut']),
              _buildDetailItem('Total', record['totalHours']),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailItem('Location', record['location']),
          if (record['notes'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Notes: ${record['notes']}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          if (record['breaks'].isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Breaks:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...record['breaks'].map<Widget>((breakTime) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${breakTime['start']} - ${breakTime['end']} (${breakTime['duration']})',
                style: TextStyle(color: Colors.grey[700]),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }


}