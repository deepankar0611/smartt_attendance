import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/attendance_screen_provider.dart';
import '../models/bottom_sheet.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  bool _isShowingBottomSheet = false;
  bool _isBlurred = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showAnimatedSnackBar(String title, String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.read<AttendanceScreenProvider>().isCheckedIn
                  ? [Colors.orange.shade800, Colors.red.shade700]
                  : [Colors.green.shade600, Colors.teal.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      message,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLocationBottomSheet(bool isCheckIn) {
    if (_isShowingBottomSheet) return;

    setState(() {
      _isShowingBottomSheet = true;
      _isBlurred = true;
    });

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => LocationBottomSheet(
        isCheckIn: isCheckIn,
      ),
    ).whenComplete(() {
      setState(() {
        _isShowingBottomSheet = false;
        _isBlurred = false;
      });
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return "$hour:${time.minute.toString().padLeft(2, '0')} $amPm";
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '--:--';
    return _formatTime(timestamp.toDate());
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceScreenProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey[50]!, Colors.grey[100]!, Colors.grey[200]!],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: _isBlurred ? 5.0 : 0.0, sigmaY: _isBlurred ? 5.0 : 0.0),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(provider),
                            const SizedBox(height: 30),
                            _buildTimeDisplay(),
                            const SizedBox(height: 40),
                            _buildAttendanceButton(provider),
                            const SizedBox(height: 40),
                            _buildAttendanceStats(provider),
                            const SizedBox(height: 20),
                            Center(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AttendanceScreenProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey ${provider.userName}!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey[800], letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.wb_sunny_rounded, size: 16, color: Colors.amber[600]),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: provider.isCheckedIn ? FontWeight.w500 : FontWeight.w400,
                    ),
                    child: Text(provider.isCheckedIn ? 'Working now' : 'Ready to start?'),
                  ),
                ],
              ),
            ],
          ),
          Hero(
            tag: 'profile',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 5,
                    spreadRadius: -2,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: provider.profileImageUrl != null && provider.profileImageUrl!.isNotEmpty
                    ? NetworkImage(provider.profileImageUrl!)
                    : const AssetImage('assets/ab.jpg') as ImageProvider,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    DateTime now = DateTime.now();
    String formattedTime = _formatTime(now);
    String formattedDate = "${_getWeekday(now.weekday)}, ${now.day} ${_getMonth(now.month)} ${now.year}";

    return Center(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.grey[800]!, Colors.grey[900]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                formattedTime,
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w300, letterSpacing: -1.5, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[50]!, Colors.grey[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(AttendanceScreenProvider provider) {
    return Center(
      child: NeumorphicCheckInButton(
        isCheckedIn: provider.isCheckedIn,
        onTap: () => _showLocationBottomSheet(provider.isCheckedIn ? false : true),
      ),
    );
  }

  Widget _buildAttendanceStats(AttendanceScreenProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10), spreadRadius: 0)],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            provider.isCheckedIn ? Icons.login_rounded : Icons.schedule_rounded,
            'Check In',
            provider.checkInTimestamp != null ? _formatTimestamp(provider.checkInTimestamp) : null,
            Colors.green.shade700,
            'check-in',
          ),
          _buildDivider(),
          _buildStatItem(
            provider.isCheckedIn ? Icons.logout_rounded : Icons.schedule_rounded,
            'Check Out',
            provider.checkOutTimestamp != null ? _formatTimestamp(provider.checkOutTimestamp) : null,
            Colors.red.shade700,
            'check-out',
          ),
          _buildDivider(),
          _buildStatItem(
            provider.isCheckedIn ? Icons.timelapse_rounded : Icons.timer_rounded,
            'Total',
            provider.totalHours,
            Colors.blue.shade700,
            'total-hours',
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[200]!.withOpacity(0.5), Colors.grey[400]!.withOpacity(0.8), Colors.grey[200]!.withOpacity(0.5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String? time, Color color, String animationKey) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 24, key: ValueKey<String>('$animationKey-$time')),
            ),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(time ?? '--:--', style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class NeumorphicCheckInButton extends StatefulWidget {
  final bool isCheckedIn;
  final VoidCallback onTap;

  const NeumorphicCheckInButton({
    super.key,
    required this.isCheckedIn,
    required this.onTap,
  });

  @override
  _NeumorphicCheckInButtonState createState() => _NeumorphicCheckInButtonState();
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
                  Text(
                    buttonText,
                    style: TextStyle(fontSize: 20, color: buttonColor),
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