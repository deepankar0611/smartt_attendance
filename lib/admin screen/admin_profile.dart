import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../student screen/delete_account_page.dart';
import '../student screen/login_screen.dart';
import '../student screen/password.dart';
import 'FriendRequestPage.dart';
import 'admin_edit_profile_sheet.dart';
import 'leave_approve_page.dart';
import 'employee_management_page.dart';

class AdminProfilePage extends StatefulWidget {
  final String? adminId;

  const AdminProfilePage({Key? key, this.adminId}) : super(key: key);

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  String? _profileImageUrl;
  String _name = "Admin User";
  String _location = "Head Office";
  String _mobile = "7479519946";
  String _email = "admin@example.com";
  String _joinDate = "01-01-2023";
  final Map<String, int> _stats = {
    'employees': 0,
    'projects': 12,
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
    } else {
      _fetchAdminProfile();
      _fetchSummaryData();
    }
  }

  Future<void> _fetchAdminProfile() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('teachers').doc(_userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String formattedJoinDate = "01-01-2023";
        if (data['createdAt'] != null) {
          Timestamp createdAt = data['createdAt'] as Timestamp;
          DateTime dateTime = createdAt.toDate();
          formattedJoinDate = DateFormat('dd-MM-yyyy').format(dateTime);
        }

        setState(() {
          _name = data['name'] ?? "Admin User";
          _location = data['location'] ?? "Head Office";
          _mobile = data['mobile'] ?? "7479519946";
          _email = data['email'] ?? "admin@example.com";
          _joinDate = formattedJoinDate;
          _profileImageUrl = data['profileImageUrl'];
        });
      } else {
        await _firestore.collection('teachers').doc(_userId).set({
          'name': _name,
          'location': _location,
          'mobile': _mobile,
          'email': _auth.currentUser?.email ?? 'admin@example.com',
          'joinDate': _joinDate,
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': _auth.currentUser?.emailVerified ?? false,
          'profileImageUrl': null,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      _showSnackBar('Error fetching admin profile: $e');
    }
  }

  Future<void> _fetchSummaryData() async {
    try {
      // Fetch employees count
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('teachers')
          .doc(_userId)
          .collection('friends')
          .get();
      int totalFriends = friendsSnapshot.docs.length;
      print('Total friends fetched: $totalFriends');

      // Fetch active projects count
      QuerySnapshot projectsSnapshot = await _firestore.collection('projects').get();
      int activeProjects = projectsSnapshot.docs.length;
      print('Active projects: $activeProjects');

      setState(() {
        _stats['employees'] = totalFriends;
        _stats['projects'] = activeProjects;
      });
    } catch (e) {
      _showSnackBar('Error fetching summary data: $e');
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
          await _supabase.storage.from('profile_pictures').remove([oldFileName]);
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      await _supabase.storage
          .from('profile_pictures')
          .upload(fileName, imageFile, fileOptions: const FileOptions(upsert: true));

      final String imageUrl = _supabase.storage.from('profile_pictures').getPublicUrl(fileName);

      await _firestore.collection('teachers').doc(_userId).update({
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

  Future<void> _logout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Colors.green.shade900,
          ),
        ),
      );
      await FirebaseAuth.instance.signOut();
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Logged out successfully');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Error logging out: $e');
    }
  }

  void _showEditProfileSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(color: Colors.transparent),
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
                initialLocation: _location,
                initialMobile: _mobile,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _name = result['name'] ?? _name;
        _location = result['location'] ?? _location;
        _mobile = result['mobile'] ?? _mobile;
      });

      try {
        await _firestore.collection('teachers').doc(_userId).update({
          'name': _name,
          'location': _location,
          'mobile': _mobile,
        });
        _showSnackBar('Admin profile updated successfully');
      } catch (e) {
        _showSnackBar('Error updating admin profile: $e');
      }
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => const PasswordChangeSheet(),
    );
  }

  void _navigateToManageLeaves() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
    );
  }

  void _navigateToEmployeeList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmployeeManagementPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          // Gradient background container
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.green.shade900,
                  Colors.green.shade800,
                ],
              ),
            ),
          ),
          // Scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProfileHeader(),
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
                      child: _buildOptionsCard(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
          // Floating action button
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              onPressed: _logout,
              backgroundColor: Colors.green.shade900,
              elevation: 4,
              child: const Icon(Icons.logout, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
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
                      Colors.green.shade400,
                      Colors.green.shade300,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
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
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              _name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email, "Email", _email),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone, "Mobile", _mobile),
          const Divider(height: 24),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.green.shade700),
          ),
          const SizedBox(width: 16),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _stats.entries.map((entry) => _buildStatItem(entry)).toList(),
      ),
    );
  }

  Widget _buildStatItem(MapEntry<String, int> entry) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Text(
              entry.value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.key,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionButton(
            icon: Icons.edit,
            label: "Edit Profile",
            onTap: _showEditProfileSheet,
          ),
          const SizedBox(height: 12),
          _buildOptionButton(
            icon: Icons.event_note,
            label: "Manage Leaves",
            onTap: _navigateToManageLeaves,
          ),
          const SizedBox(height: 12),
          _buildOptionButton(
            icon: Icons.people,
            label: "Employee Management",
            onTap: _navigateToEmployeeList,
          ),
          const SizedBox(height: 12),
          _buildOptionButton(
            icon: Icons.settings,
            label: "Settings",
            onTap: _changePassword,
          ),
          const SizedBox(height: 12),
          _buildOptionButton(
            icon: Icons.delete_forever,
            label: "Delete Account",
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeleteAccountPage(userType: 'teacher'),
                ),
              );
              if (result == 'delete') {
                _showSnackBar('Account deleted successfully');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.green.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}