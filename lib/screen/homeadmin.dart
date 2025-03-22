import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return const DashboardHome();
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.white,
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SummaryCards(),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shadowColor: Colors.grey.withOpacity(0.2),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Attendance Overview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<String>(
                            value: 'This Month',
                            items: ['This Week', 'This Month', 'Last 3 Months', 'This Year']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: AttendanceChart(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shadowColor: Colors.grey.withOpacity(0.2),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Team Performance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: TeamPerformanceChart(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shadowColor: Colors.grey.withOpacity(0.2),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Project Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add', style: TextStyle(fontSize: 12)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const ProjectStatusList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shadowColor: Colors.grey.withOpacity(0.2),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Activities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            child: const Text('View All', style: TextStyle(fontSize: 12)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const ActivityList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shadowColor: Colors.grey.withOpacity(0.2),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Top Performers',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<String>(
                            value: 'This Month',
                            items: ['This Week', 'This Month', 'This Quarter']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const TopPerformersList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: _isMenuOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Column(
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    // Add department creation logic here
                    _toggleMenu();
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  label: const Text('Department'),
                  icon: const Icon(Icons.business),
                  elevation: 4,
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  onPressed: () {
                    // Add group creation logic here
                    _toggleMenu();
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  label: const Text('Group'),
                  icon: const Icon(Icons.group),
                  elevation: 4,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: const Color(0xff006600),
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animationController,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCards extends StatelessWidget {
  const SummaryCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          context,
          title: 'Total Employees',
          value: '248',
          changePercentage: 12.5,
          iconData: Icons.people,
          iconColor: Colors.blue,
        ),
        _buildSummaryCard(
          context,
          title: 'Present Today',
          value: '211',
          changePercentage: 5.2,
          iconData: Icons.check_circle,
          iconColor: Colors.green,
        ),
        _buildSummaryCard(
          context,
          title: 'On Leave',
          value: '18',
          changePercentage: -8.3,
          iconData: Icons.calendar_today,
          iconColor: Colors.orange,
        ),
        _buildSummaryCard(
          context,
          title: 'Active Projects',
          value: '24',
          changePercentage: 4.1,
          iconData: Icons.work,
          iconColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required String title,
        required String value,
        required double changePercentage,
        required IconData iconData,
        required Color iconColor,
      }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  changePercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: changePercentage >= 0 ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${changePercentage.abs()}%',
                  style: TextStyle(
                    color: changePercentage >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'last month',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class AttendanceChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final labels = ['1', '5', '10', '15', '20', '25', '30'];
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()}%',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          // Present Line
          LineChartBarData(
            spots: const [
              FlSpot(0, 85),
              FlSpot(1, 83),
              FlSpot(2, 88),
              FlSpot(3, 87),
              FlSpot(4, 90),
              FlSpot(5, 85),
              FlSpot(6, 87),
            ],
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          // Late Line
          LineChartBarData(
            spots: const [
              FlSpot(0, 10),
              FlSpot(1, 12),
              FlSpot(2, 9),
              FlSpot(3, 8),
              FlSpot(4, 7),
              FlSpot(5, 10),
              FlSpot(6, 8),
            ],
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.1),
            ),
          ),
          // Absent Line
          LineChartBarData(
            spots: const [
              FlSpot(0, 5),
              FlSpot(1, 5),
              FlSpot(2, 3),
              FlSpot(3, 5),
              FlSpot(4, 3),
              FlSpot(5, 5),
              FlSpot(6, 5),
            ],
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(

            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final color = barSpot.bar.color;
                String status;
                if (color == Colors.green) {
                  status = 'Present';
                } else if (color == Colors.orange) {
                  status = 'Late';
                } else {
                  status = 'Absent';
                }
                return LineTooltipItem(
                  '${status}: ${barSpot.y.toInt()}%',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class TeamPerformanceChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(

            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final teams = ['Dev Team', 'Design', 'QA', 'Marketing', 'Sales'];
              return BarTooltipItem(
                '${teams[groupIndex]}: ${rod.toY.toInt()}%',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final teams = ['Dev', 'Design', 'QA', 'Mktg', 'Sales'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    teams[value.toInt()],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()}%',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: 92,
                color: Colors.blue,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: 85,
                color: Colors.purple,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: 88,
                color: Colors.green,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: 78,
                color: Colors.orange,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [
              BarChartRodData(
                toY: 82,
                color: Colors.red,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProjectStatusList extends StatelessWidget {
  const ProjectStatusList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectData = [
      {
        'name': 'Mobile App Redesign',
        'team': 'Design Team',
        'deadline': '28 Mar',
        'progress': 0.75,
        'color': Colors.blue,
      },
      {
        'name': 'API Integration',
        'team': 'Development',
        'deadline': '15 Apr',
        'progress': 0.45,
        'color': Colors.purple,
      },
      {
        'name': 'Dashboard Updates',
        'team': 'UI/UX',
        'deadline': '10 Apr',
        'progress': 0.6,
        'color': Colors.green,
      },
      {
        'name': 'Testing Phase 2',
        'team': 'QA Team',
        'deadline': '22 Mar',
        'progress': 0.9,
        'color': Colors.orange,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projectData.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final project = projectData[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project['team'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Deadline: ${project['deadline']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),

                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: project['progress'] as double,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(project['color'] as Color),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}

class ActivityList extends StatelessWidget {
  const ActivityList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'user': 'Jane Cooper',
        'action': 'checked in',
        'time': '15 minutes ago',
        'avatar': 'https://i.pravatar.cc/150?img=5',
      },
      {
        'user': 'Esther Howard',
        'action': 'requested leave',
        'time': '45 minutes ago',
        'avatar': 'https://i.pravatar.cc/150?img=2',
      },
      {
        'user': 'Robert Fox',
        'action': 'completed task',
        'time': '1 hour ago',
        'avatar': 'https://i.pravatar.cc/150?img=8',
      },
      {
        'user': 'Wade Warren',
        'action': 'joined project',
        'time': '2 hours ago',
        'avatar': 'https://i.pravatar.cc/150?img=4',
      },
      {
        'user': 'Leslie Alexander',
        'action': 'checked out',
        'time': '3 hours ago',
        'avatar': 'https://i.pravatar.cc/150?img=1',
      },
    ];
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: NetworkImage(activity['avatar'] as String),
          ),
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: activity['user'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' '),
                TextSpan(text: activity['action'] as String),
              ],
            ),
          ),
          subtitle: Text(
            activity['time'] as String,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        );
      },
    );
  }
}

class TopPerformersList extends StatelessWidget {
  const TopPerformersList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final performers = [
      {
        'name': 'Cameron Williamson',
        'position': 'UI/UX Designer',
        'hours': 176,
        'progress': 0.95,
        'avatar': 'https://i.pravatar.cc/150?img=6',
      },
      {
        'name': 'Dianne Russell',
        'position': 'Senior Developer',
        'hours': 168,
        'progress': 0.92,
        'avatar': 'https://i.pravatar.cc/150?img=10',
      },
      {
        'name': 'Jenny Wilson',
        'position': 'Project Manager',
        'hours': 165,
        'progress': 0.9,
        'avatar': 'https://i.pravatar.cc/150?img=3',
      },
      {
        'name': 'Guy Hawkins',
        'position': 'QA Specialist',
        'hours': 160,
        'progress': 0.88,
        'avatar': 'https://i.pravatar.cc/150?img=12',
      },
    ];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: performers.length,
      itemBuilder: (context, index) {
        final performer = performers[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(performer['avatar'] as String),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      performer['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      performer['position'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${performer['hours']} hrs',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),

                ],
              ),
            ],
          ),
        );
      },
    );
  }
}