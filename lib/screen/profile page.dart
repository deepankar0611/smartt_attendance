import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartt_attendance/screen/settingsheet.dart';
import 'dart:io';

import 'login_screen.dart';
import 'edit_profile_sheet.dart'; // Add this import

class ModernProfilePage extends StatefulWidget {
  const ModernProfilePage({Key? key}) : super(key: key);

  @override
  _ModernProfilePageState createState() => _ModernProfilePageState();
}

class _ModernProfilePageState extends State<ModernProfilePage> {
  File? _profileImage;
  String _name = "Aryan bansal";
  String _job = "Flutter developer";
  String _location = "chandigarh";
  Map<String, int> _stats = {
    'Projects': 12,
    'Attended': 25,
    'Leaves': 2,
  };

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _showSnackBar('Logged out successfully');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showSnackBar('Error logging out: $e');
    }
  }

  void _showEditProfileSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make sheet background transparent
      builder: (context) => Stack(
        children: [
          // Blur effect for background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(
              color: Colors.black.withOpacity(0.2), // Semi-transparent overlay
            ),
          ),
          // The actual edit profile sheet
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
              ),
              child: EditProfileSheet(
                initialName: _name,
                initialJob: _job,
                initialLocation: _location,
                initialProjects: _stats['Projects']!,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _name = result['name'];
        _job = result['job'];
        _location = result['location'];
        _stats['Projects'] = result['projects'];
      });
      _showSnackBar('Profile updated successfully');
    }
  }
  void _showSettingsSheet() async {
    final result = await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
              ),
              child: const SettingsSheet(),
            ),
          ),
        ],
      ),
    );

    if (result == 'update') {
      _showSnackBar('Password update requested');
    } else if (result == 'delete') {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        _showSnackBar('Account deleted successfully');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
        );
      } catch (e) {
        _showSnackBar('Error deleting account: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color baseColor = Color(0xFF1B5E20);
    final Color gradientStart = baseColor;
    final Color gradientEnd = baseColor.withOpacity(0.8);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        toolbarHeight: 5,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(gradientStart, gradientEnd),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildUserStatsRow(),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildOptionsCard(baseColor),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        backgroundColor: baseColor,
        child: const Icon(Icons.logout),
      ),
    );
  }

  Widget _buildProfileHeader(Color gradientStart, Color gradientEnd) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [gradientStart, gradientEnd],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [gradientStart.withOpacity(0.9), gradientEnd.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Hero(
                tag: 'profile-image',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    image: const DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/12.jpg'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _job,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text(
                  _location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _stats.entries
            .map(
              (entry) => Expanded(
            child: Column(
              children: [
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }
  Widget _buildOptionsCard(Color baseColor) {
    return Column(
      children: [
        _buildOptionButton(
          icon: Icons.edit,
          label: "Edit Profile",
          onTap: _showEditProfileSheet, // Updated to show the sheet
        ),
        const SizedBox(height: 16),
        _buildOptionButton(
          icon: Icons.settings,
          label: "Settings",
          onTap: _showSettingsSheet,
        ),
        const SizedBox(height: 16),
        _buildOptionButton(
          icon: Icons.person_add,
          label: "Connect Friends",
          onTap: () => _showSnackBar('Connect Friends tapped'),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}