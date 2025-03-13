import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Make sure this is in pubspec.yaml
import 'package:google_fonts/google_fonts.dart'; // Add to pubspec.yaml
import 'package:fl_chart/fl_chart.dart'; // Add to pubspec.yaml for charts

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final List<Map<String, dynamic>> _classes = [
    {
      'className': 'Math 101',
      'startTime': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      'endTime': DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      'attendance': {
        'student1': true,
        'student2': false,
        'student3': true,
        'student4': true,
        'student5': false,
      },
    },
    {
      'className': 'History 202',
      'startTime': DateTime.now().subtract(const Duration(hours: 3)),
      'endTime': DateTime.now().subtract(const Duration(hours: 2)),
      'attendance': {
        'student1': false,
        'student4': true,
        'student5': true,
        'student6': true,
        'student7': false,
      },
    },
    {
      'className': "Physics",
      'startTime': DateTime.now(),
      'endTime': DateTime.now().add(const Duration(hours: 1)),
      'attendance': {
        'student1': true,
        'student2': true,
        'student3': true,
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.teal,
            pinned: true, // Keeps the app bar visible
            expandedHeight: 150.0, // Space for the title
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Welcome, Teacher Name!', // Dynamic name later
                style: GoogleFonts.lato( // Use Google Fonts
                  textStyle: const TextStyle(color: Colors.white),
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.plusCircle), // Use Lucide Icons
                onPressed: () {
                  _showAddClassDialog(context);
                },
                tooltip: 'Add Class',
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return _buildClassCard(_classes[index], index);
              },
              childCount: _classes.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData, int index) {
    String className = classData['className'] ?? 'Unnamed Class';
    DateTime startTime = classData['startTime'];

    String formattedDate = DateFormat('MMM dd, y').format(startTime);

    // Calculate attendance percentage
    int presentCount = 0;
    int totalStudents = 0;
    if (classData['attendance'] != null) {
      classData['attendance'].forEach((studentId, isPresent) {
        totalStudents++;
        if (isPresent) {
          presentCount++;
        }
      });
    }
    double attendancePercentage =
    totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showClassDetails(context, classData, index);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row( // Use a Row for side-by-side layout
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded( // Class details take up most of the space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: $formattedDate',
                      style: GoogleFonts.roboto(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attendance: ${attendancePercentage.toStringAsFixed(0)}% (${presentCount}/${totalStudents})',
                      style: GoogleFonts.roboto(fontSize: 16),
                    )
                  ],
                ),
              ),
              SizedBox( // Add some spacing
                width: 100, // Adjust width as needed
                height: 100,
                child: _buildAttendanceChart(attendancePercentage),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceChart(double attendancePercentage) {
    return PieChart(
      PieChartData(
        sectionsSpace: 0, // Remove space between sections
        centerSpaceRadius: 30, // Adjust size of the hole
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: attendancePercentage,
            title: '${attendancePercentage.toStringAsFixed(0)}%', // Show percentage
            titleStyle: GoogleFonts.roboto( // Consistent font
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white
            ),
            radius: 20,
          ),
          PieChartSectionData(
            color: Colors.grey[300]!,
            value: 100 - attendancePercentage,
            title: '', // No title for the "absent" section
            radius: 20,
          ),
        ],
        borderData: FlBorderData(
          show: false, // No border
        ),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final TextEditingController classNameController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedStartTime = TimeOfDay.now();
    TimeOfDay selectedEndTime = TimeOfDay(
        hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute);

    // Helper functions for date and time selection
    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2025),
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
        });
      }
    }

    Future<void> selectTime(BuildContext context, bool isStartTime) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: isStartTime ? selectedStartTime : selectedEndTime,
      );
      if (picked != null) {
        setState(() {
          if (isStartTime) {
            selectedStartTime = picked;
          } else {
            selectedEndTime = picked;
          }
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder for the dialog
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add New Class'),
              content: SingleChildScrollView(
                // For smaller screens
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: classNameController,
                      decoration: const InputDecoration(labelText: 'Class Name'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                          "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => selectDate(context),
                    ),
                    ListTile(
                      title: Text(
                          "Start Time: ${selectedStartTime.format(context)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => selectTime(context, true),
                    ),
                    ListTile(
                      title:
                      Text("End Time: ${selectedEndTime.format(context)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => selectTime(context, false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Combine date and time objects
                    DateTime startDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedStartTime.hour,
                      selectedStartTime.minute,
                    );
                    DateTime endDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedEndTime.hour,
                      selectedEndTime.minute,
                    );
                    // Validate inputs
                    if (classNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a class name')),
                      );
                      return; // Stop execution if validation fails
                    }

                    if (endDateTime.isBefore(startDateTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text('End time cannot be before start time')),
                      );
                      return; // Stop execution if validation fails
                    }

                    // Add the new class to the _classes list
                    setState(() {
                      _classes.add({
                        'className': classNameController.text.trim(),
                        'startTime': startDateTime,
                        'endTime': endDateTime,
                        'attendance': {},
                      });
                    });

                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showClassDetails(
      BuildContext context, Map<String, dynamic> classData, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(classData['className'] ?? 'Class Details'),
          content: SingleChildScrollView(
            // Important for variable content height
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Start Time: ${DateFormat('MMM dd, బాగా - hh:mm a').format(classData['startTime'])}'),
                Text('End Time: ${DateFormat('hh:mm a').format(classData['endTime'])}'),
                const SizedBox(height: 16),
                const Text('Attendance:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                // Display attendance list
                ..._buildAttendanceList(classData['attendance']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                _showAttendanceDialog(context, classData, index);
              },
              child: const Text('Take Attendance'),
            ),
            ElevatedButton(
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text('Are you sure you want to delete this class?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Delete'),
                          onPressed: () {
                            // Delete the class from the list
                            setState(() {
                              _classes.removeAt(index);
                            });
                            Navigator.of(context).pop(); // Close confirmation dialog
                            Navigator.of(context).pop(); // Close details dialog
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Set button color to red
              ),
              child: const Text('Delete Class', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  List<Widget> _buildAttendanceList(Map<String, dynamic>? attendance) {
    if (attendance == null || attendance.isEmpty) {
      return [const Text('No attendance data available.')];
    }

    List<Widget> attendanceWidgets = [];
    attendance.forEach((studentId, isPresent) {
      // In a real app, you'd fetch student names from Firestore using studentId
      String studentName = "Student $studentId"; // Placeholder
      attendanceWidgets.add(
        ListTile(
          title: Text(studentName),
          trailing: Text(isPresent ? 'Present' : 'Absent'),
        ),
      );
    });
    return attendanceWidgets;
  }

  void _showAttendanceDialog(
      BuildContext context, Map<String, dynamic> classData, int classIndex) {

    // Create a local copy of attendance to modify
    Map<String, dynamic> localAttendance =
    Map.from(classData['attendance'] ?? {});

    // Create a list with some sample students.  In your real app,
    // you would get this from your 'students' collection in Firestore.
    List<Map<String, dynamic>> sampleStudents = [
      {'id': 'student1', 'name': 'Alice'},
      {'id': 'student2', 'name': 'Bob'},
      {'id': 'student3', 'name': 'Charlie'},
      {'id': 'student4', 'name': 'David'},
      {'id': 'student5', 'name': 'Eve'},
      {'id': 'student6', 'name': 'Karim'},
      {'id': 'student7', 'name': 'Rahim'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Take Attendance'),
          content: SizedBox(
            width: double.maxFinite, // Important for horizontal scrolling, if needed
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Build CheckboxListTiles *dynamically* from the sampleStudents list
                  ...sampleStudents.map((student) {
                    String studentId = student['id']!;
                    String studentName = student['name']!;

                    // Use the localAttendance map for the initial value AND updates
                    bool isPresent = localAttendance[studentId] ?? false;

                    return StatefulBuilder(  // Add StatefulBuilder here
                      builder: (BuildContext context, StateSetter setState) {
                        return CheckboxListTile(
                          title: Text(studentName),
                          value: isPresent,
                          onChanged: (bool? value) {
                            setState(() { // Update *local* state
                              localAttendance[studentId] = value ?? false;
                            });
                          },
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update the attendance in the _classes list using the localAttendance map
                setState(() {
                  _classes[classIndex]['attendance'] = localAttendance;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance Updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}