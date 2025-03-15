import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  @override
  _AttendanceHistoryScreenState createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime selectedDate = DateTime(2022, 10, 26);
  DateTime currentMonth = DateTime(2022, 10);

  // Random attendance data
  final List<Map<String, dynamic>> attendanceData = [
    {'date': DateTime(2022, 10, 3), 'checkIn': '08:15', 'checkOut': '17:30', 'totalHours': '9h 15m', 'location': 'Main Office'},
    {'date': DateTime(2022, 10, 4), 'checkIn': '08:00', 'checkOut': '16:45', 'totalHours': '8h 45m', 'location': 'Branch A'},
    {'date': DateTime(2022, 10, 5), 'checkIn': '09:00', 'checkOut': '18:00', 'totalHours': '9h', 'location': 'Main Office'},
    {'date': DateTime(2022, 10, 10), 'checkIn': '08:30', 'checkOut': '17:15', 'totalHours': '8h 45m', 'location': 'Branch B'},
    {'date': DateTime(2022, 10, 15), 'checkIn': '07:45', 'checkOut': '16:30', 'totalHours': '8h 45m', 'location': 'Main Office'},
    {'date': DateTime(2022, 10, 22), 'checkIn': '08:20', 'checkOut': '17:50', 'totalHours': '9h 30m', 'location': 'Branch A'},
    {'date': DateTime(2022, 11, 1), 'checkIn': '08:10', 'checkOut': '17:20', 'totalHours': '9h 10m', 'location': 'Main Office'},
  ];

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  List<Map<String, dynamic>> _filterAttendanceByMonth() {
    return attendanceData.where((record) {
      DateTime recordDate = record['date'] as DateTime;
      return recordDate.year == currentMonth.year && recordDate.month == currentMonth.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAttendance = _filterAttendanceByMonth();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Attendance History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.green[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              children: [
                // Month Navigator Card
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), offset: Offset(4, 4), blurRadius: 10, spreadRadius: 1),
                      BoxShadow(color: Colors.white.withOpacity(0.8), offset: Offset(-4, -4), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                  child: _buildMonthNavigator(),
                ),
                SizedBox(height: 40),
                // Larger Calendar Card
                Container(
                  height: MediaQuery.of(context).size.height * 0.45, // Larger calendar
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), offset: Offset(4, 4), blurRadius: 10, spreadRadius: 1),
                      BoxShadow(color: Colors.white.withOpacity(0.8), offset: Offset(-4, -4), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                  child: _buildCalendar(),
                ),
                SizedBox(height: 30), // Increased spacing
              ],
            ),
            // History Card positioned at bottom fourth
            // History Card positioned at bottom half
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.height * 0.35, // Changed from 0.25 to 0.5 for half the screen
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey[400]!, offset: Offset(4, 4), blurRadius: 10, spreadRadius: 1),
                    BoxShadow(color: Colors.white.withOpacity(0.8), offset: Offset(-4, -4), blurRadius: 10, spreadRadius: 1),
                  ],
                ),
                child: SingleChildScrollView(
                  child: filteredAttendance.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No attendance records for this month.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  )
                      : _buildAttendanceList(filteredAttendance),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NeumorphicButton(icon: Icons.arrow_left, onTap: _previousMonth, label: 'Prev'),
        Text(DateFormat('MMMM yyyy').format(currentMonth), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        NeumorphicButton(icon: Icons.arrow_right, onTap: _nextMonth, label: 'Next'),
      ],
    );
  }

  Widget _buildCalendar() {
    List<Widget> dayWidgets = [];
    List<String> days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    for (var day in days) {
      dayWidgets.add(
        Expanded(
          child: Center(
            child: Text(day, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          ),
        ),
      );
    }

    DateTime firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    int firstWeekday = firstDayOfMonth.weekday % 7;
    int daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    List<Widget> dateWidgets = [];
    for (int i = 0; i < firstWeekday; i++) {
      dateWidgets.add(Expanded(child: Container()));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDay = DateTime(currentMonth.year, currentMonth.month, day);
      bool isSelected = currentDay.day == selectedDate.day && currentDay.month == selectedDate.month && currentDay.year == selectedDate.year;

      dateWidgets.add(
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedDate = currentDay),
            child: Container(
              margin: EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> rows = [];
    for (int i = 0; i < dateWidgets.length; i += 7) {
      List<Widget> rowChildren = dateWidgets.sublist(i, i + 7 > dateWidgets.length ? dateWidgets.length : i + 7);
      while (rowChildren.length < 7) {
        rowChildren.add(Expanded(child: Container()));
      }
      rows.add(Row(children: rowChildren));
    }

    return Column(
      children: [
        Row(children: dayWidgets),
        SizedBox(height: 20),
        Expanded(child: Column(children: rows)),
      ],
    );
  }

  Widget _buildAttendanceList(List<Map<String, dynamic>> filteredAttendance) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredAttendance.length,
      itemBuilder: (context, index) {
        final record = filteredAttendance[index];
        final recordDate = record['date'] as DateTime;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: recordDate.day == 22 ? Colors.orange : Colors.grey[300],
                ),
                child: Center(
                  child: Text(
                    recordDate.day.toString(),
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRichText('Check In', record['checkIn'] ?? '---:---'),
                        _buildRichText('Check Out', record['checkOut'] ?? '---:---'),
                        _buildRichText('Total Hrs', record['totalHours'] ?? '---:---'),
                      ],
                    ),
                    SizedBox(height: 4),
                    if (record['location'] != null)
                      Text(record['location'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRichText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

class NeumorphicButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  const NeumorphicButton({required this.icon, required this.onTap, this.label});

  @override
  _NeumorphicButtonState createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: widget.label != null ? 80 : 40,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.white38,
          boxShadow: _isPressed
              ? [
            BoxShadow(color: Colors.grey.withOpacity(0.2), offset: Offset(2, 2), blurRadius: 5, spreadRadius: 1),
            BoxShadow(color: Colors.white.withOpacity(0.8), offset: Offset(-2, -2), blurRadius: 5, spreadRadius: 1),
          ]
              : [
            BoxShadow(color: Colors.grey.withOpacity(0.2), offset: Offset(3, 3), blurRadius: 5, spreadRadius: 1),
            BoxShadow(color: Colors.white.withOpacity(0.8), offset: Offset(-3, -3), blurRadius: 5, spreadRadius: 1),
          ],
        ),
        child: Center(
          child: widget.label != null
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.black87, size: 20),
              SizedBox(width: 4),
              Text(widget.label!, style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
            ],
          )
              : Icon(widget.icon, color: Colors.black87, size: 24),
        ),
      ),
    );
  }
}