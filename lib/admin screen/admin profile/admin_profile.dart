import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../student screen/delete_account_page.dart';
import '../../student screen/login_screen.dart';
import '../../student screen/password.dart';
import 'admin_edit_profile_sheet.dart';
import 'employee management/employee_management_page.dart';
import '../../providers/admin_profile_provider.dart';
import 'leave/leave_approve_page.dart';

class AdminProfilePage extends StatefulWidget {
  final String? adminId;

  const AdminProfilePage({super.key, this.adminId});

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.adminId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    if (_userId.isNotEmpty) {
      final provider = Provider.of<AdminProfileProvider>(context, listen: false);
      provider.fetchAdminProfile(_userId);
      provider.fetchSummaryData(_userId);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    final provider = Provider.of<AdminProfileProvider>(context, listen: false);
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
                initialName: provider.name,
                initialLocation: provider.location,
                initialMobile: provider.mobile,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      await provider.updateProfile(
        _userId,
        result['name'] ?? provider.name,
        result['location'] ?? provider.location,
        result['mobile'] ?? provider.mobile,
      );
      _showSnackBar('Admin profile updated successfully');
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
      MaterialPageRoute(builder: (context) => const LeaveApprovePage()),
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
      body: Consumer<AdminProfileProvider>(
        builder: (context, provider, child) {
          return Stack(
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
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            _buildProfileHeader(provider),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: _buildAdminInfoCard(provider),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: _buildUserStatsRow(provider),
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
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AdminProfileProvider provider) {
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
                          image: provider.profileImageUrl != null && provider.profileImageUrl!.isNotEmpty
                              ? NetworkImage(provider.profileImageUrl!)
                              : const AssetImage('assets/admin_default.jpg') as ImageProvider,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: provider.isUploading ? null : () => provider.pickAndUploadImage(_userId),
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
                        child: provider.isUploading
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
              provider.name,
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
                  provider.location,
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

  Widget _buildAdminInfoCard(AdminProfileProvider provider) {
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
          _buildInfoRow(Icons.email, "Email", provider.email),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone, "Mobile", provider.mobile),
          const Divider(height: 24),
          _buildInfoRow(Icons.calendar_today, "Join Date", provider.joinDate),
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

  Widget _buildUserStatsRow(AdminProfileProvider provider) {
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
        children: provider.stats.entries.map((entry) => _buildStatItem(entry)).toList(),
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