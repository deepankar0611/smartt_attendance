import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:smartt_attendance/screen/check_in_out_screen.dart';

class BottomNavigationBarr extends StatefulWidget {
  const BottomNavigationBarr({super.key});

  @override
  State<BottomNavigationBarr> createState() => _BottomNavigationBarr();
}

class _BottomNavigationBarr extends State<BottomNavigationBarr> {
  final PersistentTabController _controller = PersistentTabController(initialIndex: 0);

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      navBarStyle: NavBarStyle.style15, // Floating center button style
      backgroundColor: Colors.white,
    );
  }

  List<Widget> _buildScreens() {
    return [
      const CheckInOutScreen(),
      Center(child: Text('Search Screen')),
      Center(child: Text('Add Screen')),
      Center(child: Text('Messages Screen')),
      Center(child: Text('Settings Screen')),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home, size: 22), // Adjust icon size
        title: "Home",
        textStyle: TextStyle(fontSize: 12, height: 1.0), // Reduce space
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
        contentPadding: 0, // Minimize spacing
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.search, size: 22),
        title: "Search",
        textStyle: TextStyle(fontSize: 12, height: 1.0),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
        contentPadding: 0,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.add, size: 28),
        title: "Add",
        textStyle: TextStyle(fontSize: 12, height: 1.0),
        activeColorPrimary: Colors.white,
        inactiveColorPrimary: Colors.white,
        activeColorSecondary: Colors.blue,
        contentPadding: 0,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.message, size: 22),
        title: "Messages",
        textStyle: TextStyle(fontSize: 12, height: 1.0),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
        contentPadding: 0,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.settings, size: 22),
        title: "Settings",
        textStyle: TextStyle(fontSize: 12, height: 1.0),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
        contentPadding: 0,
      ),
    ];
  }
}
