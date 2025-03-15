import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ModernProfilePage extends StatefulWidget {
  const ModernProfilePage({Key? key}) : super(key: key);

  @override
  _ModernProfilePageState createState() => _ModernProfilePageState();
}

class _ModernProfilePageState extends State<ModernProfilePage>
    with SingleTickerProviderStateMixin {
  File? _profileImage;
  late TabController _tabController;
  bool _isDarkMode = false;

  final Map<String, int> _stats = {
    'Projects': 12,
    'Followers': 243,
    'Following': 168,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } else {
      _showSnackBar('Photo permission denied');
    }
  }

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

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  void _logout() {
    _showSnackBar('Logged out');
    // Add actual logout logic here
  }

  @override
  Widget build(BuildContext context) {
    // Base color for the app
    final Color baseColor = const Color(0xFF1B5E20); // Dark Green

    final ThemeData theme = _isDarkMode
        ? ThemeData.dark().copyWith(
      primaryColor: baseColor,
      colorScheme: ColorScheme.dark(
        primary: baseColor,
        secondary: baseColor.withOpacity(0.7),
        surface: const Color(0xFF212121),
      ),
    )
        : ThemeData.light().copyWith(
      primaryColor: baseColor,
      colorScheme: ColorScheme.light(
        primary: baseColor,
        secondary: baseColor.withOpacity(0.7),
        surface: Colors.white,
      ),
    );

    final Color gradientStart = baseColor;
    final Color gradientEnd = baseColor.withOpacity(0.8);
    final Color backgroundColor = _isDarkMode ? const Color(0xFF121212) : Colors.grey[100]!;
    final Color textColor = _isDarkMode ? Colors.white : Colors.black87;
    final Color subtitleColor = _isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color cardColor = _isDarkMode ? Colors.grey[850]! : Colors.white;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: baseColor,
          elevation: 0,
          toolbarHeight: 5,

        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(gradientStart, gradientEnd, textColor),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildUserStatsRow(textColor, subtitleColor, cardColor),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildOptionsCard(theme, textColor, baseColor),
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
      ),
    );
  }

  Widget _buildProfileHeader(Color gradientStart, Color gradientEnd, Color textColor) {
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
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
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
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/default_profile.jpg') as ImageProvider,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Richie Lorie",
              style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Senior UI/UX Designer",
            style: GoogleFonts.poppins(
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
                borderRadius: BorderRadius.circular(15)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text(
                  "San Francisco, CA",
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatsRow(Color textColor, Color subtitleColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
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
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: subtitleColor,
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

  Widget _buildOptionsCard(ThemeData theme, Color textColor, Color baseColor) {
    return Column(
      children: [
        _buildOptionButton(
          theme,
          icon: Icons.edit,
          label: "Edit Profile",
          color: Colors.white,
          onTap: () => _showSnackBar('Edit Profile tapped'),
        ),
        const SizedBox(height: 16),
        _buildOptionButton(
          theme,
          icon: Icons.settings,
          label: "Settings",
          color: Colors.white,
          onTap: () => _showSnackBar('Settings tapped'),
        ),
        const SizedBox(height: 16),
        _buildOptionButton(
          theme,
          icon: Icons.person_add,
          label: "Connect Friends",
          color: Colors.white,
          onTap: () => _showSnackBar('Connect Friends tapped'),
        ),
      ],
    );
  }

  Widget _buildOptionButton(ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: color,
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
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}