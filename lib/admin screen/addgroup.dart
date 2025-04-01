import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProjectAssignmentScreen extends StatefulWidget {
  const ProjectAssignmentScreen({super.key});

  @override
  State<ProjectAssignmentScreen> createState() => _ProjectAssignmentScreenState();
}

class _ProjectAssignmentScreenState extends State<ProjectAssignmentScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 14));
  List<File>? _projectFiles;

  final List<Map<String, dynamic>> _allEmployees = [
    {'id': 1, 'name': 'Emma Johnson', 'role': 'UI Developer', 'avatar': 'assets/avatars/emma.jpg', 'department': 'Design'},
    {'id': 2, 'name': 'Michael Chen', 'role': 'Frontend Developer', 'avatar': 'assets/avatars/michael.jpg', 'department': 'Engineering'},
    {'id': 3, 'name': 'Sarah Williams', 'role': 'Project Manager', 'avatar': 'assets/avatars/sarah.jpg', 'department': 'Management'},
    {'id': 4, 'name': 'David Kim', 'role': 'Backend Developer', 'avatar': 'assets/avatars/david.jpg', 'department': 'Engineering'},
    {'id': 5, 'name': 'Alex Rodriguez', 'role': 'UX Researcher', 'avatar': 'assets/avatars/alex.jpg', 'department': 'Design'},
    {'id': 6, 'name': 'Lisa Patel', 'role': 'QA Engineer', 'avatar': 'assets/avatars/lisa.jpg', 'department': 'Engineering'},
    {'id': 7, 'name': 'John Smith', 'role': 'DevOps Engineer', 'avatar': 'assets/avatars/john.jpg', 'department': 'Operations'},
    {'id': 8, 'name': 'Olivia Brown', 'role': 'Content Strategist', 'avatar': 'assets/avatars/olivia.jpg', 'department': 'Marketing'},
  ];

  final List<Map<String, dynamic>> _selectedEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  final List<String> _departments = ['All', 'Engineering', 'Design', 'Management', 'Operations', 'Marketing'];

  @override
  void initState() {
    super.initState();
    _filteredEmployees = List.from(_allEmployees);
  }

  void _filterEmployees() {
    setState(() {
      _filteredEmployees = _allEmployees.where((employee) =>
      (_selectedDepartment == 'All' || employee['department'] == _selectedDepartment) &&
          employee['name'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    });
  }

  void _toggleEmployeeSelection(Map<String, dynamic> employee) {
    setState(() {
      if (_selectedEmployees.any((e) => e['id'] == employee['id'])) {
        _selectedEmployees.removeWhere((e) => e['id'] == employee['id']);
      } else {
        _selectedEmployees.add(employee);
      }
    });
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
    if (result != null) {
      setState(() {
        _projectFiles = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Assign Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff003300), Color(0xff006600)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Project Details Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(LucideIcons.briefcase, color: Colors.green.shade700, size: 22),
                    const SizedBox(width: 8),
                    const Text('Project Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _projectNameController,
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(LucideIcons.fileText, size: 20),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _projectDescriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Project Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 40), child: Icon(LucideIcons.alignLeft, size: 20)),
                      alignLabelWithHint: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Icon(LucideIcons.calendar, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text('Deadline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _deadline,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(primary: Colors.green.shade700),
                            dialogBackgroundColor: Colors.white,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null && picked != _deadline) setState(() => _deadline = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 12),
                          Text(DateFormat('MMM dd, yyyy').format(_deadline), style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
                          const Spacer(),
                          Icon(LucideIcons.chevronDown, size: 18, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: Icon(LucideIcons.upload, size: 18),
                    label: const Text('Upload Files'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  if (_projectFiles != null && _projectFiles!.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.fileCheck, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text('${_projectFiles!.length} files selected', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Employee Selection Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(LucideIcons.users, color: Colors.green.shade700, size: 22),
                            const SizedBox(width: 8),
                            const Text('Employees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search employees...',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    prefixIcon: Icon(LucideIcons.search, size: 20, color: Colors.grey.shade600),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade400, width: 1.5)),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    _searchQuery = value;
                                    _filterEmployees();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                  color: Colors.grey.shade50,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedDepartment,
                                    icon: Icon(LucideIcons.chevronDown, size: 18, color: Colors.grey.shade600),
                                    items: _departments.map((department) => DropdownMenuItem(
                                      value: department,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.briefcase, size: 16, color: department == 'All' ? Colors.grey.shade600 : Colors.green.shade700),
                                          const SizedBox(width: 8),
                                          Text(department),
                                        ],
                                      ),
                                    )).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDepartment = value!;
                                        _filterEmployees();
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = _filteredEmployees[index];
                          final isSelected = _selectedEmployees.any((e) => e['id'] == employee['id']);
                          return ListTile(
                            leading: CircleAvatar(backgroundImage: AssetImage(employee['avatar']), backgroundColor: Colors.grey.shade200),
                            title: Text(employee['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.green.shade700 : Colors.grey.shade800)),
                            subtitle: Text('${employee['role']} • ${employee['department']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: Colors.green.shade700,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (value) => _toggleEmployeeSelection(employee),
                            ),
                            onTap: () => _toggleEmployeeSelection(employee),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Row(children: [
                              Icon(LucideIcons.userCheck, size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 6),
                              Text('${_selectedEmployees.length} selected', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green.shade700)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Selected Employees Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(LucideIcons.userCheck, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text('Selected Employees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_selectedEmployees.isNotEmpty)
                            IconButton(
                              icon: Icon(LucideIcons.trash2, size: 18, color: Colors.grey.shade700),
                              onPressed: () => setState(() => _selectedEmployees.clear()),
                              tooltip: 'Clear all',
                              style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100, padding: const EdgeInsets.all(8)),
                            ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _selectedEmployees.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        Icon(LucideIcons.userMinus, size: 36, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No employees selected yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ]),
                    )
                        : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _selectedEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = _selectedEmployees[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(backgroundImage: AssetImage(employee['avatar']), radius: 16, backgroundColor: Colors.grey.shade200),
                            title: Text(employee['name']),
                            subtitle: Text(employee['role']),
                            trailing: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _toggleEmployeeSelection(employee)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_selectedEmployees.length} employees selected', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                    if (_selectedEmployees.isNotEmpty)
                      Text('Tap to review selection', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _selectedEmployees.isEmpty
                      ? null
                      : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Project assigned successfully!'),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Assign Project'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    minimumSize: const Size(0, 48),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}