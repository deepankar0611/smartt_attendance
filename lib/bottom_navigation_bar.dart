import 'package:flutter/material.dart';
import 'package:smartt_attendance/screen/attendance-screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AttendanceScreen(),
    Center(child: Text("Home Screen", style: TextStyle(fontSize: 24))),
    Center(child: Text("Profile Screen", style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected screen
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(25),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.green[900],
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Home", 0),
            _buildNavItem(Icons.calendar_month, "Attendance", 1),
            _buildNavItem(Icons.person, "Profile", 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        height: 50, // Increased height of brown box
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 10),
        decoration: isSelected
            ? BoxDecoration(
          color: Colors.brown[300],
          borderRadius: BorderRadius.circular(30),
        )
            : null,
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  label,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

