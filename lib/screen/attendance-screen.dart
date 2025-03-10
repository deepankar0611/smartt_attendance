import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isCheckedIn = false; // Track check-in status
  DateTime? _checkInDateTime; // Store check-in DateTime for calculation
  String? _checkInTime; // Store check-in time for display
  String? _checkOutTime; // Store check-out time for display
  String? _totalHours; // Store total hours worked

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

  @override
  void dispose() {
    super.dispose();
  }

  void _handleCheckInCheckOut() {
    setState(() {
      DateTime now = DateTime.now();
      if (_isCheckedIn) {
        // Handle Check Out
        _checkOutTime = "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

        // Calculate total hours worked
        if (_checkInDateTime != null) {
          Duration difference = now.difference(_checkInDateTime!);
          int hours = difference.inHours;
          int minutes = difference.inMinutes.remainder(60);
          _totalHours = "${hours}h ${minutes}m";
        }

        // Reset for next cycle
        _isCheckedIn = false;
        _checkInDateTime = null;
        print("Checked Out at $_checkOutTime, Total Hours: $_totalHours");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Checked Out at $_checkOutTime\nTotal Hours: $_totalHours")),
        );
      } else {
        // Handle Check In
        _checkInDateTime = now;
        _checkInTime = "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
        _checkOutTime = null; // Clear previous check-out time
        _totalHours = null; // Clear previous total hours
        _isCheckedIn = true;
        print("Checked In at $_checkInTime");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Checked In at $_checkInTime")),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedTime = "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
    String formattedDate = "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year} - ${DateTime.now().weekday == 1 ? 'Monday' : DateTime.now().weekday == 2 ? 'Tuesday' : DateTime.now().weekday == 3 ? 'Wednesday' : DateTime.now().weekday == 4 ? 'Thursday' : DateTime.now().weekday == 5 ? 'Friday' : DateTime.now().weekday == 6 ? 'Saturday' : 'Sunday'}";

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey Deepankar!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Good morning! Mark your attendance',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                        'https://via.placeholder.com/150'), // Replace with actual image URL
                  ),
                ],
              ),
            ),
            // Time and Date Section (Real-time from user's phone)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Clickable Neumorphic Check In/Check Out Button
            Center(
              child: NeumorphicCheckInButton(
                isCheckedIn: _isCheckedIn,
                onTap: _handleCheckInCheckOut,
              ),
            ),
            SizedBox(height: 90),
            // Additional Options with Custom Icons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCustomOption(
                    Icons.arrow_downward,
                    'Check In',
                    time: _checkInTime,
                  ),
                  _buildCustomOption(
                    Icons.arrow_upward,
                    'Check Out',
                    time: _checkOutTime,
                  ),
                  _buildCustomOption(
                    Icons.check,
                    'Total Hrs',
                    time: _totalHours,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            child: Icon(
              icon,
              size: 30,
              color: Colors.green,
            ),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        if (time != null) ...[
          SizedBox(height: 5),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
        // Remove dotted line when time is present
        if (time == null) ...[
          SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) => Container(
              width: 4,
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
            )),
          ),
        ],
      ],
    );
  }
}

// Neumorphic Check In Button as a StatefulWidget to handle press state
class NeumorphicCheckInButton extends StatefulWidget {
  final bool isCheckedIn;
  final VoidCallback onTap;

  NeumorphicCheckInButton({required this.isCheckedIn, required this.onTap});

  @override
  _NeumorphicCheckInButtonState createState() => _NeumorphicCheckInButtonState();
}

class _NeumorphicCheckInButtonState extends State<NeumorphicCheckInButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor = widget.isCheckedIn ? Colors.red : Colors.green;
    String buttonText = widget.isCheckedIn ? "Check Out" : "Check In";

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
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
                    color: _isPressed ? Colors.grey[400]! : Colors.white.withOpacity(0.8),
                    offset: _isPressed ? Offset(5, 5) : Offset(-5, -5),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: _isPressed ? Colors.white.withOpacity(0.8) : Colors.grey[400]!,
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
                    color: _isPressed ? Colors.white.withOpacity(0.7) : Colors.grey[500]!,
                    offset: _isPressed ? Offset(-5, -5) : Offset(5, 5),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: _isPressed ? Colors.grey[500]! : Colors.white.withOpacity(0.7),
                    offset: _isPressed ? Offset(5, 5) : Offset(-5, -5),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 40,
                    color: buttonColor,
                  ),
                  SizedBox(height: 10),
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 20,
                      color: buttonColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}