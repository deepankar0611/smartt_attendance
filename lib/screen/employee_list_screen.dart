import 'package:flutter/material.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({Key? key}) : super(key: key);

  @override
  _EmployeeListScreenState createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final List<Map<String, dynamic>> _allEmployees = [
    {'name': 'John Doe', 'role': 'Developer', 'department': 'IT', 'adminCompany': ''},
    {'name': 'Jane Smith', 'role': 'Designer', 'department': 'Creative', 'adminCompany': ''},
    {'name': 'Mike Johnson', 'role': 'Manager', 'department': 'Operations', 'adminCompany': ''},
    {'name': 'Sarah Williams', 'role': 'Analyst', 'department': 'Finance', 'adminCompany': ''},
  ];

  // List of available admin companies
  final List<String> _adminCompanies = [
    'Acme Corp',
    'Globex Inc',
    'Umbrella LLC',
    'Wayne Enterprises'
  ];

  List<Map<String, dynamic>> _filteredEmployees = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showFullList = false;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'IT', 'Creative', 'Operations', 'Finance'];
  String _adminCompanyFilter = 'All';

  @override
  void initState() {
    super.initState();
    _filteredEmployees = List.from(_allEmployees);
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _allEmployees.where((employee) {
        final name = employee['name']?.toLowerCase() ?? '';
        final role = employee['role']?.toLowerCase() ?? '';
        final department = employee['department']?.toLowerCase() ?? '';
        final adminCompany = employee['adminCompany']?.toLowerCase() ?? '';

        bool matchesSearch = name.contains(query) ||
            role.contains(query) ||
            department.contains(query);

        bool matchesDepartmentFilter = _selectedFilter == 'All' ||
            department == _selectedFilter.toLowerCase();

        bool matchesAdminCompany = _adminCompanyFilter == 'All' ||
            adminCompany == _adminCompanyFilter.toLowerCase() ||
            (_adminCompanyFilter == 'None' && adminCompany.isEmpty);

        return matchesSearch && matchesDepartmentFilter && matchesAdminCompany;
      }).toList();
    });
  }


  void _setDepartmentFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterEmployees();
    });
  }

  void _setAdminCompanyFilter(String filter) {
    setState(() {
      _adminCompanyFilter = filter;
      _filterEmployees();
    });
  }

  void _assignAdminCompany(int employeeIndex, String company) {
    setState(() {
      // Find the actual index in the full list
      final employeeData = _filteredEmployees[employeeIndex];
      final fullListIndex = _allEmployees.indexWhere((e) =>
      e['name'] == employeeData['name'] &&
          e['role'] == employeeData['role'] &&
          e['department'] == employeeData['department']
      );

      if (fullListIndex >= 0) {
        _allEmployees[fullListIndex]['adminCompany'] = company;
        _filteredEmployees[employeeIndex]['adminCompany'] = company;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Employees',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
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
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced search section with shadow and better spacing
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.green[700],
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _filterEmployees();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),

          // Department filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      _setDepartmentFilter(filter);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.green[800] : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.green[800]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Counter and results info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredEmployees.length} employees found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_adminCompanyFilter != 'All')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Admin: $_adminCompanyFilter',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            _setAdminCompanyFilter('All');
                          },
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _buildEmployeeList(),
          ),
        ],
      ),
    );
  }
  void _showFilterBottomSheet(BuildContext context) {
    // Create a list with 'All', 'None', and all admin companies
    final adminFilterOptions = ['All', 'None', ..._adminCompanies];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Admin Company',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: adminFilterOptions.map((company) {
                      final isSelected = _adminCompanyFilter == company;
                      return FilterChip(
                        label: Text(company),
                        selected: isSelected,
                        onSelected: (selected) {
                          setSheetState(() {
                            _adminCompanyFilter = company;
                          });
                          setState(() {
                            _adminCompanyFilter = company;
                            _filterEmployees();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.green[100],
                        checkmarkColor: Colors.green[800],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.green[800] : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Department',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setSheetState(() {
                            _selectedFilter = filter;
                          });
                          setState(() {
                            _selectedFilter = filter;
                            _filterEmployees();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.green[100],
                        checkmarkColor: Colors.green[800],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.green[800] : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignDepartmentBottomSheet(BuildContext context, int employeeIndex, String employeeName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assign $employeeName to Admin Company',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Select admin company:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('None (Clear Assignment)'),
                      leading: const Icon(Icons.clear, color: Colors.grey),
                      onTap: () {
                        _assignAdminCompany(employeeIndex, '');
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1),
                    ..._adminCompanies.map((company) {
                      return ListTile(
                        title: Text(company),
                        leading: const Icon(Icons.business, color: Colors.green),
                        trailing: _filteredEmployees[employeeIndex]['adminCompany'] == company
                            ? Icon(Icons.check_circle, color: Colors.green[700])
                            : null,
                        onTap: () {
                          _assignAdminCompany(employeeIndex, company);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildEmployeeList() {
    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No employees found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        final name = employee['name'] ?? 'Unknown';
        final role = employee['role'] ?? 'No Role';
        final department = employee['department'] ?? 'No Department';
        final adminCompany = employee['adminCompany'] ?? '';

        // Get department color
        Color departmentColor;
        switch (department.toLowerCase()) {
          case 'it':
            departmentColor = Colors.blue;
            break;
          case 'creative':
            departmentColor = Colors.purple;
            break;
          case 'operations':
            departmentColor = Colors.orange;
            break;
          case 'finance':
            departmentColor = Colors.teal;
            break;
          default:
            departmentColor = Colors.grey;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: departmentColor.withOpacity(0.15),
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: TextStyle(
                  color: departmentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: departmentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        department,
                        style: TextStyle(
                          color: departmentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (adminCompany.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.business,
                              size: 10,
                              color: Colors.amber[800],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              adminCompany,
                              style: TextStyle(
                                color: Colors.amber[800],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.add_business,
                color: Colors.green[700],
              ),
              onPressed: () {
                _showAssignDepartmentBottomSheet(context, index, name);
              },
            ),
          ),
        );
      },
    );
  }
}