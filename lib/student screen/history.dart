import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../provider/attendance_history_notifier.dart';
import '../providers/attendance_history_provider.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({Key? key, required String userEmail, required List attendanceData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceHistoryProvider(),
      child: const _AttendanceHistoryView(),
    );
  }
}

class _AttendanceHistoryView extends StatefulWidget {
  const _AttendanceHistoryView();

  @override
  State<_AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<_AttendanceHistoryView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceHistoryProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Attendance History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsCard(provider),
                        _buildViewToggle(provider),
                        const SizedBox(height: 16),
                        provider.isListView
                            ? _buildAttendanceListView(provider)
                            : _buildCalendarView(provider),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(AttendanceHistoryProvider provider) {
    final stats = provider.getMonthlyStats();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(provider.currentMonth),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats['workdays']} Workdays',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(title: 'Total Hours', value: stats['totalHours'], icon: Icons.access_time),
                _buildStatItem(title: 'Avg Hours/Day', value: stats['avgHours'], icon: Icons.trending_up),
                _buildStatItem(title: 'On Time', value: '${stats['onTime']}/${stats['workdays']}', icon: Icons.check_circle_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(AttendanceHistoryProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildNavigationButton(Icons.arrow_back_ios_new, () {
                provider.previousMonth();
                _animationController.reset();
                _animationController.forward();
              }),
              const SizedBox(width: 8),
              _buildNavigationButton(Icons.arrow_forward_ios, () {
                provider.nextMonth();
                _animationController.reset();
                _animationController.forward();
              }),
            ],
          ),
          Container(
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => provider.toggleListView(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: provider.isListView ? Colors.white38 : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: provider.isListView
                          ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Icon(Icons.view_list, color: provider.isListView ? Colors.blue[700] : Colors.grey[600]),
                  ),
                ),
                GestureDetector(
                  onTap: () => provider.toggleListView(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !provider.isListView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: !provider.isListView
                          ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Icon(Icons.calendar_month, color: !provider.isListView ? Colors.blue[700] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String title, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.black, size: 16),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: Colors.black, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IconButton(icon: Icon(icon, size: 20, color: Colors.grey[700]), onPressed: onPressed),
    );
  }

  Widget _buildAttendanceListView(AttendanceHistoryProvider provider) {
    if (provider.attendanceData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No attendance data for ${DateFormat('MMMM yyyy').format(provider.currentMonth)}',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.attendanceData.length,
      itemBuilder: (context, index) {
        final record = provider.attendanceData[index];
        final date = record['date'];
        DateTime recordDate = date is Timestamp ? date.toDate() : DateTime.now();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.white],
              ),
              borderRadius: BorderRadius.circular(12),
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
                        DateFormat('EEE, MMM d').format(recordDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: provider.getStatusColor(record['status']?.toString() ?? 'Unknown').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record['status']?.toString() ?? 'Unknown',
                          style: TextStyle(
                            color: provider.getStatusColor(record['status']?.toString() ?? 'Unknown'),
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
                      _buildTimeColumn('Check In', record['checkInTime'], record['checkInLocation'], provider),
                      _buildTimeColumn('Check Out', record['checkOutTime'], record['checkOutLocation'], provider),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Text(record['totalHours']?.toString() ?? '0h 0m', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  if ((record['notes']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Notes: ${record['notes']}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeColumn(String label, dynamic time, dynamic location, AttendanceHistoryProvider provider) {
    String formattedTime = '--:--';
    if (time != null) {
      try {
        DateTime timeDate;
        if (time is Timestamp) {
          timeDate = time.toDate();
        } else {
          timeDate = DateFormat('HH:mm').parse(time);
        }
        formattedTime = DateFormat('h:mm a').format(timeDate);
      } catch (e) {
        print('Error parsing time: $e');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(formattedTime, style: const TextStyle(fontSize: 16)),
        if (location != null)
          FutureBuilder<String>(
            future: provider.getPlaceName(location['latitude'], location['longitude']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Loading location...', style: TextStyle(color: Colors.grey[600], fontSize: 12));
              }
              if (snapshot.hasError) {
                return Text('Error fetching location', style: TextStyle(color: Colors.grey[600], fontSize: 12));
              }
              return Text('Loc: ${snapshot.data}', style: TextStyle(color: Colors.grey[600], fontSize: 12));
            },
          ),
      ],
    );
  }

  Widget _buildCalendarView(AttendanceHistoryProvider provider) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(provider.currentMonth.year - 1),
          lastDay: DateTime(provider.currentMonth.year + 1),
          focusedDay: provider.currentMonth,
          selectedDayPredicate: (day) => _isSameDay(provider.selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            provider.selectDate(selectedDay, focusedDay);
          },
          calendarFormat: CalendarFormat.month,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Colors.blue[700], shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Colors.blue[500], shape: BoxShape.circle),
            markerDecoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              bool hasAttendance = provider.attendanceData.any((record) {
                final recordDate = record['date'] is Timestamp ? (record['date'] as Timestamp).toDate() : DateTime.now();
                return _isSameDay(recordDate, date);
              });
              if (hasAttendance) {
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildSelectedDayDetail(provider),
      ],
    );
  }

  Widget _buildSelectedDayDetail(AttendanceHistoryProvider provider) {
    final selectedDayRecord = provider.getSelectedDayRecord(provider.selectedDate);
    if (selectedDayRecord == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No attendance data for ${DateFormat('MMMM d, yyyy').format(provider.selectedDate)}',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    final date = selectedDayRecord['date'];
    DateTime recordDate = date is Timestamp ? date.toDate() : DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(recordDate),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: provider.getStatusColor(selectedDayRecord['status'] ?? 'Unknown').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  selectedDayRecord['status'] ?? 'Unknown',
                  style: TextStyle(
                    color: provider.getStatusColor(selectedDayRecord['status'] ?? 'Unknown'),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildDetailItem('Check In', _formatTime(selectedDayRecord['checkInTime'])),
              if (selectedDayRecord['checkInLocation'] != null)
                FutureBuilder<String>(
                  future: provider.getPlaceName(
                    selectedDayRecord['checkInLocation']['latitude'],
                    selectedDayRecord['checkInLocation']['longitude'],
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildDetailItem('Check In Loc', 'Loading...');
                    }
                    if (snapshot.hasError) {
                      return _buildDetailItem('Check In Loc', 'Error');
                    }
                    return _buildDetailItem('Check In Loc', snapshot.data ?? 'Unknown');
                  },
                ),
              _buildDetailItem('Check Out', _formatTime(selectedDayRecord['checkOutTime'])),
              if (selectedDayRecord['checkOutLocation'] != null)
                FutureBuilder<String>(
                  future: provider.getPlaceName(
                    selectedDayRecord['checkOutLocation']['latitude'],
                    selectedDayRecord['checkOutLocation']['longitude'],
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildDetailItem('Check Out Loc', 'Loading...');
                    }
                    if (snapshot.hasError) {
                      return _buildDetailItem('Check Out Loc', 'Error');
                    }
                    return _buildDetailItem('Check Out Loc', snapshot.data ?? 'Unknown');
                  },
                ),
              _buildDetailItem('Total', selectedDayRecord['totalHours'] ?? '0h 0m'),
            ],
          ),
          if ((selectedDayRecord['notes'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Notes: ${selectedDayRecord['notes']}', style: TextStyle(color: Colors.grey[700])),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';
    try {
      DateTime timeDate;
      if (time is Timestamp) {
        timeDate = time.toDate();
      } else {
        timeDate = DateFormat('HH:mm').parse(time);
      }
      return DateFormat('h:mm a').format(timeDate);
    } catch (e) {
      print('Error parsing time: $e');
      return '--:--';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}