import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartt_attendance/screen/settingsheet.dart';
import 'dart:io';
import 'employee_list_screen.dart';
import 'login_screen.dart';
import 'admin_edit_profile_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProfilePage extends StatefulWidget {
  final String? adminId;

  const AdminProfilePage({Key? key, this.adminId}) : super(key: key);

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  String? _profileImageUrl;
  String _name = "Admin User";
  String _role = "System Administrator";
  String _department = "IT Department";
  String _location = "Head Office";
  String _mobile = "7479519946";
  String _email = "admin@example.com";
  String _joinDate = "01-01-2023";
  String _adminLevel = "Super Admin";
  String _adminId = "";
  final Map<String, int> _stats = {
    'Students': 150,
    'Teachers': 25,
    'Courses': 12,
  };

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.adminId ?? _auth.currentUser?.uid ?? '';
    if (_userId.isEmpty) {
      print('No user is currently signed in.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      _fetchAdminProfile();
      _fetchSystemStats();
    }
  }

  Future<void> _fetchAdminProfile() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('admins').doc(_userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _name = data['name'] ?? "Admin User";
          _role = data['role'] ?? "System Administrator";
          _department = data['department'] ?? "IT Department";
          _location = data['location'] ?? "Head Office";
          _mobile = data['mobile'] ?? "7479519946";
          _email = data['email'] ?? "admin@example.com";
          _joinDate = data['joinDate'] ?? "01-01-2023";
          _adminLevel = data['adminLevel'] ?? "Super Admin";
          _adminId = data['adminId'] ?? "A-" + _userId.substring(0, 6);
          _profileImageUrl = data['profileImageUrl'];
        });
      } else {
        await _firestore.collection('admins').doc(_userId).set({
          'name': _name,
          'role': _role,
          'department': _department,
          'location': _location,
          'mobile': _mobile,
          'email': _auth.currentUser?.email ?? 'admin@example.com',
          'joinDate': _joinDate,
          'adminLevel': _adminLevel,
          'adminId': "A-" + _userId.substring(0, 6),
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': _auth.currentUser?.emailVerified ?? false,
          'profileImageUrl': null,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      _showSnackBar('Error fetching admin profile: $e');
    }
  }

  Future<void> _fetchSystemStats() async {
    try {
      final studentSnapshot = await _firestore.collection('students').count().get();
      int? studentCount = studentSnapshot.count;

      final teacherSnapshot = await _firestore.collection('teachers').count().get();
      int? teacherCount = teacherSnapshot.count;

      final courseSnapshot = await _firestore.collection('courses').count().get();
      int? courseCount = courseSnapshot.count;

      setState(() {
        _stats['Students'] = studentCount!;
        _stats['Teachers'] = teacherCount!;
        _stats['Courses'] = courseCount!;
      });
    } catch (e) {
      _showSnackBar('Error fetching system stats: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Camera'),
            ),
          ],
        ),
      );

      if (source == null) return;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      String fileName = '$_userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      File imageFile = File(pickedFile.path);

      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        String oldFileName = _profileImageUrl!.split('/').last;
        try {
          await _supabase.storage.from('profile-pictures').remove([oldFileName]);
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      final String imageUrl = _supabase.storage.from('admin_profile_pictures').getPublicUrl(fileName);

      await _firestore.collection('admins').doc(_userId).update({
        'profileImageUrl': imageUrl,
      });

      setState(() {
        _profileImageUrl = imageUrl;
      });

      _showSnackBar('Profile picture updated successfully');
    } catch (e) {
      _showSnackBar('Error uploading image: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
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
      backgroundColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
              ),
              child: AdminEditProfileSheet(
                initialName: _name,
                initialRole: _role,
                initialDepartment: _department,
                initialLocation: _location,
                initialMobile: _mobile,
                initialAdminLevel: _adminLevel,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _name = result['name'];
        _role = result['role'];
        _department = result['department'];
        _location = result['location'];
        _mobile = result['mobile'];
        _adminLevel = result['adminLevel'];
      });

      try {
        await _firestore.collection('admins').doc(_userId).update({
          'name': _name,
          'role': _role,
          'department': _department,
          'location': _location,
          'mobile': _mobile,
          'adminLevel': _adminLevel,
        });
        _showSnackBar('Admin profile updated successfully');
      } catch (e) {
        _showSnackBar('Error updating admin profile: $e');
      }
    }
  }

  void _navigateToSettingsPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );

    if (result == 'update') {
      _showSnackBar('Password updated successfully');
    } else if (result == 'delete') {
      try {
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

  void _viewAuditLogs() {
    _showSnackBar('Audit logs feature will be implemented soon');
  }

  @override
  Widget build(BuildContext context) {
    const Color baseColor = Colors.green;
    final Color gradientStart = baseColor;
    final Color gradientEnd = Color.fromRGBO(0, 255, 0, 0.8); // Previously baseColor.withOpacity(0.8)

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        elevation: 0,
        toolbarHeight: 5,
      ),
      body: Column(
        children: [
          _buildProfileHeader(gradientStart, gradientEnd),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildAdminInfoCard(),
                  ),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        backgroundColor: Colors.green.shade900,
        child: const Icon(Icons.logout, color: Colors.white),
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
          colors: [
            const Color(0xFF1B5E20),
            Color.fromRGBO(27, 94, 32, 0.8), // Previously 0xFF1B5E20.withOpacity(0.8)
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15), // Previously Colors.black.withOpacity(0.15)
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
                    colors: [
                      Color.fromRGBO(0, 255, 0, 0.9), // Previously gradientStart.withOpacity(0.9)
                      Color.fromRGBO(0, 255, 0, 0.7), // Previously gradientEnd.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Hero(
                tag: 'profile-image',
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!)
                              : const AssetImage('assets/admin_default.jpg') as ImageProvider,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: _isUploading
                            ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        )
                            : const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.2), // Previously Colors.black.withOpacity(0.2)
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.2), // Previously Colors.white.withOpacity(0.2)
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "ID: $_adminId",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Previously Colors.white.withOpacity(0.9)
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _role,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white, // Previously Colors.white.withOpacity(0.9)
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.1), // Previously Colors.white.withOpacity(0.1)
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

  Widget _buildAdminInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05), // Previously Colors.black.withOpacity(0.05)
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.business, "Department", _department),
          const Divider(height: 16),
          _buildInfoRow(Icons.email, "Email", _email),
          const Divider(height: 16),
          _buildInfoRow(Icons.phone, "Mobile", _mobile),
          const Divider(height: 16),
          _buildInfoRow(Icons.calendar_today, "Join Date", _joinDate),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.right,
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
            color: Color.fromRGBO(0, 0, 0, 0.05), // Previously Colors.black.withOpacity(0.05)
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

  void _navigateToEmployeeList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployeeListScreen(),
      ),
    );
  }

  Widget _buildOptionsCard(Color baseColor) {
    return Column(
      children: [
        _buildOptionButton(
          icon: Icons.edit,
          label: "Edit Profile",
          onTap: _showEditProfileSheet,
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        _buildOptionButton(
          icon: Icons.history,
          label: "View Audit Logs",
          onTap: _viewAuditLogs,
        ),
        const SizedBox(height: 16),
        _buildOptionButton(
          icon: Icons.settings,
          label: "Settings",
          onTap: _navigateToSettingsPage,
        ),
        const SizedBox(height: 16),
        _buildOptionButton(
          icon: Icons.ad_units,
          label: "Add employee",
          onTap: _navigateToEmployeeList,
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
              color: Color.fromRGBO(0, 0, 0, 0.2), // Previously Colors.black.withOpacity(0.2)
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