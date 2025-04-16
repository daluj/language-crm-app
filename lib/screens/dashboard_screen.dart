import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_model.dart';
import '../models/class_model.dart';
import '../models/payment_model.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final StudentProvider _studentProvider = StudentProvider();
  final ClassProvider _classProvider = ClassProvider();
  final PaymentProvider _paymentProvider = PaymentProvider();
  
  bool _isLoading = true;
  int _studentCount = 0;
  Map<String, int> _classStats = {};
  Map<String, dynamic> _paymentStats = {};
  List<Class> _upcomingClasses = [];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );
    _animationController.forward();
    _loadDashboardData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load data in parallel for better performance
      final studentCountFuture = _studentProvider.getStudentCount();
      final classStatsFuture = _classProvider.getClassesStatistics();
      final paymentStatsFuture = _paymentProvider.getPaymentStatistics();
      final upcomingClassesFuture = _classProvider.getUpcomingClasses();
      
      // Wait for all futures to complete
      final results = await Future.wait([
        studentCountFuture,
        classStatsFuture,
        paymentStatsFuture,
        upcomingClassesFuture,
      ]);
      
      setState(() {
        _studentCount = results[0] as int;
        _classStats = results[1] as Map<String, int>;
        _paymentStats = results[2] as Map<String, dynamic>;
        _upcomingClasses = results[3] as List<Class>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreeting(),
                      SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                      _buildStatCards(),
                      SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                      _buildRevenueChart(),
                      SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                      SectionHeader(
                        title: 'Upcoming Classes',
                        actionLabel: 'Schedule',
                        actionIcon: Icons.add_circle_outline,
                        onActionPressed: () {
                          // Navigate to schedule class screen
                        },
                      ),
                      SizedBox(height: 8),
                      _buildUpcomingClasses(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
        ),
        SizedBox(height: 4),
        Text(
          'Here\'s your teaching summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
  
  Widget _buildStatCards() {
    final formatter = NumberFormat.currency(symbol: '\$');
    
    // Always use 2 columns for stat cards
    return LayoutBuilder(builder: (context, constraints) {
      // Calculate appropriate aspect ratio based on available width
      // Smaller screens need taller cards (smaller aspect ratio)
      final childAspectRatio = constraints.maxWidth < 600 ? 2.0 : 1.4;
      
      return GridView.count(
        crossAxisCount: 2, // Always 2 cards per row
        crossAxisSpacing: constraints.maxWidth < 600 ? 8 : 16, // Smaller spacing on small screens
        mainAxisSpacing: constraints.maxWidth < 600 ? 8 : 16,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: childAspectRatio,
        children: [
          StatCard(
            title: 'Total Students',
            value: _studentCount.toString(),
            icon: Icons.people,
            color: Color(0xFF6750A4),
          ),
          StatCard(
            title: 'This Month',
            value: _classStats['month']?.toString() ?? '0',
            icon: Icons.event_note,
            color: Color(0xFF7D5260),
          ),
          StatCard(
            title: 'Monthly Revenue',
            value: formatter.format(_paymentStats['month'] ?? 0),
            icon: Icons.payments,
            color: Color(0xFF625B71),
          ),
          StatCard(
            title: 'Pending Payments',
            value: formatter.format(_paymentStats['pending'] ?? 0),
            icon: Icons.receipt_long,
            color: Colors.orange,
          ),
        ],
      );
    });
  }
  
  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Adjust chart height based on available width
                final chartHeight = constraints.maxWidth < 600 ? 150.0 : 200.0;
                // Adjust bar width based on available width
                final barWidth = constraints.maxWidth < 600 ? 12.0 : 20.0;
                
                return SizedBox(
                  height: chartHeight,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 2000, // Adjust based on your data
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipPadding: EdgeInsets.all(8),
                          tooltipMargin: 4,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            const List<String> months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                            return BarTooltipItem(
                              '${months[groupIndex]}: \$${rod.toY.round()}',
                              TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const List<String> months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                              final style = TextStyle(
                                color: Colors.grey[600],
                                fontSize: constraints.maxWidth < 600 ? 10 : 12,
                              );
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(months[value.toInt()], style: style),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final style = TextStyle(
                                color: Colors.grey[600],
                                fontSize: constraints.maxWidth < 600 ? 10 : 12,
                              );
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text('\$${value.toInt()}', style: style),
                              );
                            },
                            reservedSize: constraints.maxWidth < 600 ? 28 : 40,
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 500,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: [
                        // Sample data - in real app, replace with actual data
                        _buildBarGroup(0, 1100, barWidth),
                        _buildBarGroup(1, 1500, barWidth),
                        _buildBarGroup(2, 1000, barWidth),
                        _buildBarGroup(3, 1800, barWidth),
                        _buildBarGroup(4, 1200, barWidth),
                        _buildBarGroup(5, 1600, barWidth),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  BarChartGroupData _buildBarGroup(int x, double y, [double width = 20]) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Theme.of(context).colorScheme.primary,
          width: width,
          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 2000,
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUpcomingClasses() {
    if (_upcomingClasses.isEmpty) {
      return EmptyStateWidget(
        message: 'No upcoming classes scheduled',
        icon: Icons.event_busy,
        actionLabel: 'Schedule Class',
        onActionPressed: () {
          // Navigate to schedule class screen
        },
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _upcomingClasses.length > 5 ? 5 : _upcomingClasses.length,
      itemBuilder: (context, index) {
        final classItem = _upcomingClasses[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                classItem.title.substring(0, 1),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            title: Text(classItem.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        classItem.formattedDateTime,
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        classItem.formattedDuration,
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: StatusBadge(status: classItem.status, compact: true),
            onTap: () {
              // Navigate to class details
            },
          ),
        );
      },
    );
  }
}