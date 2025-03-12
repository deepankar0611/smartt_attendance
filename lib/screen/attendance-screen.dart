import 'package:flutter/material.dart';
import '../models/bottom_sheet.dart';
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isCheckedIn = false;
  DateTime? _checkInDateTime;
  String? _checkInTime;
  String? _checkOutTime;
  String? _totalHours;
  bool _isShowingBottomSheet = false; // Add flag to prevent multiple triggers

  @override
  void initState() {
    super.initState();
    _startTimeUpdating();
  }

  void _startTimeUpdating() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (mounted) setState(() {});
      return true;
    });
  }

  void _handleCheckIn(DateTime punchTime) {
    print("Handling Check-In at $punchTime");
    setState(() {
      _isCheckedIn = true;
      _checkInDateTime = punchTime;
      _checkInTime =
      "${punchTime.hour}:${punchTime.minute.toString().padLeft(2, '0')} ${punchTime.hour >= 12 ? 'PM' : 'AM'}";
      _checkOutTime = null;
      _totalHours = null;
      _isShowingBottomSheet = false; // Reset flag
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Checked In at $_checkInTime")),
    );
  }

  void _handleCheckOut(DateTime punchTime) {
    print("Handling Check-Out at $punchTime");
    setState(() {
      _checkOutTime =
      "${punchTime.hour}:${punchTime.minute.toString().padLeft(2, '0')} ${punchTime.hour >= 12 ? 'PM' : 'AM'}";
      if (_checkInDateTime != null) {
        Duration difference = punchTime.difference(_checkInDateTime!);
        int hours = difference.inHours;
        int minutes = difference.inMinutes.remainder(60);
        _totalHours = "${hours}h ${minutes}m";
      }
      _isCheckedIn = false;
      _checkInDateTime = null;
      _isShowingBottomSheet = false; // Reset flag
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Checked Out at $_checkOutTime\nTotal Hours: $_totalHours")),
    );
  }

  void _showLocationBottomSheet(bool isCheckIn) {
    if (_isShowingBottomSheet) {
      print("Bottom sheet already showing, skipping");
      return; // Prevent multiple bottom sheets
    }
    print("Showing bottom sheet for ${isCheckIn ? 'Check-In' : 'Check-Out'}");
    setState(() => _isShowingBottomSheet = true);
    showModalBottomSheet(
      context: context,
      builder: (context) => LocationBottomSheet(
        onPunchIn: _handleCheckIn,
        onPunchOut: isCheckIn ? null : _handleCheckOut,
        isCheckIn: isCheckIn,
      ),
    ).whenComplete(() {
      print("Bottom sheet closed");
      setState(() => _isShowingBottomSheet = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedTime =
        "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
    String formattedDate =
        "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year} - ${_getWeekday(now.weekday)}";

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hey Deepankar!',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Good morning! Mark your attendance',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                    NetworkImage('https://via.placeholder.com/150'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  Text(formattedTime,
                      style:
                      TextStyle(fontSize: 48, fontWeight: FontWeight.normal)),
                  Text(formattedDate,
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
            Center(
              child: NeumorphicCheckInButton(
                isCheckedIn: _isCheckedIn,
                onTap: () => _showLocationBottomSheet(_isCheckedIn ? false : true),
              ),
            ),
            SizedBox(height: 90),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCustomOption(Icons.arrow_downward, 'Check In',
                      time: _checkInTime),
                  _buildCustomOption(Icons.arrow_upward, 'Check Out',
                      time: _checkOutTime),
                  _buildCustomOption(Icons.check, 'Total Hrs',
                      time: _totalHours),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekday(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  Widget _buildCustomOption(IconData icon, String label, {String? time}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Center(
            child: Icon(icon, size: 30, color: Colors.green),
          ),
        ),
        SizedBox(height: 5),
        Text(label,
            style: TextStyle(fontSize: 16, color: Colors.grey)),
        if (time != null) ...[
          SizedBox(height: 5),
          Text(time, style: TextStyle(fontSize: 14, color: Colors.grey)),
        ] else ...[
          SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                5,
                    (index) => Container(
                  width: 4,
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.grey),
                )),
          ),
        ],
      ],
    );
  }
}

class NeumorphicCheckInButton extends StatefulWidget {
  final bool isCheckedIn;
  final VoidCallback onTap;

  const NeumorphicCheckInButton(
      {super.key, required this.isCheckedIn, required this.onTap});

  @override
  _NeumorphicCheckInButtonState createState() =>
      _NeumorphicCheckInButtonState();
}

class _NeumorphicCheckInButtonState extends State<NeumorphicCheckInButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color buttonColor = widget.isCheckedIn ? Colors.red : Colors.green;
    String buttonText = widget.isCheckedIn ? "Check Out" : "Check In";

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        print("Button tapped: ${widget.isCheckedIn ? 'Check Out' : 'Check In'}");
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? Colors.grey[400]!
                        : Colors.white.withOpacity(0.8),
                    offset: _isPressed ? Offset(5, 5) : Offset(-5, -5),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: _isPressed
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[400]!,
                    offset: _isPressed ? Offset(-5, -5) : Offset(5, 5),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey[500]!,
                    offset: _isPressed ? Offset(-5, -5) : Offset(5, 5),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: _isPressed
                        ? Colors.grey[500]!
                        : Colors.white.withOpacity(0.7),
                    offset: _isPressed ? Offset(5, 5) : Offset(-5, -5),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 40, color: buttonColor),
                  SizedBox(height: 10),
                  Text(buttonText,
                      style: TextStyle(fontSize: 20, color: buttonColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}