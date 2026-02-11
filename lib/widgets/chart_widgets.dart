// lib/widgets/chart_widgets.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/payout_model.dart';

class PaymentMethodChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const PaymentMethodChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No payment data available'),
          ],
        ),
      );
    }

    final total = data.values.fold<num>(0, (sum, value) => sum + (value ?? 0));
    if (total == 0) {
      return const Center(child: Text('No transactions yet'));
    }

    final sections = data.entries.where((entry) => entry.value > 0).map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = _getColorForPaymentMethod(entry.key);
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        color: color,
        radius: 80,
        titlePositionPercentageOffset: 0.7,
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.entries.where((entry) => entry.value > 0).map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getColorForPaymentMethod(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _formatMethodName(entry.key),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getColorForPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return Colors.blue;
      case 'bank':
      case 'bank_transfer':
        return Colors.green;
      case 'wallet':
      case 'digital_wallet':
        return Colors.purple;
      case 'instant_eft':
        return Colors.orange;
      case 'crypto':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return 'Card';
      case 'bank':
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'wallet':
      case 'digital_wallet':
        return 'Digital Wallet';
      case 'instant_eft':
        return 'Instant EFT';
      case 'crypto':
        return 'Crypto';
      default:
        return method;
    }
  }
}

class RevenueTrendChart extends StatelessWidget {
  final List<dynamic> data;
  final String title;

  const RevenueTrendChart({
    Key? key, 
    required this.data,
    this.title = 'Revenue Trend',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('No $title data available'),
          ],
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) {
      final revenue = (entry.value['revenue'] ?? 0.0).toDouble();
      return FlSpot(entry.key.toDouble(), revenue);
    }).toList();

    final maxY = spots.isNotEmpty 
        ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
        : 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('R0');
                      return Text(
                        'R${_formatNumber(value)}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: data.length > 7 ? (data.length / 7).ceil().toDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        final date = DateTime.parse(data[index]['date']);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('M/d').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
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
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: maxY * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: const Color(0xFF00A651),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF00A651).withOpacity(0.3),
                        const Color(0xFF00A651).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF00A651),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < data.length) {
                        final date = DateTime.parse(data[index]['date']);
                        return LineTooltipItem(
                          '${DateFormat('MMM dd').format(date)}\nR${spot.y.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

class TransactionStatusChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const TransactionStatusChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.donut_small, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No transaction data available'),
          ],
        ),
      );
    }

    final total = data.values.fold<num>(0, (sum, value) => sum + (value ?? 0));
    if (total == 0) {
      return const Center(child: Text('No transactions yet'));
    }

    final sections = data.entries.where((entry) => entry.value > 0).map((entry) {
      final percentage = (entry.value / total) * 100;
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        color: _getColorForStatus(entry.key),
        radius: 60,
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusLegend(),
      ],
    );
  }

  Widget _buildStatusLegend() {
    return Column(
      children: data.entries.where((entry) => entry.value > 0).map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getColorForStatus(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatStatusName(entry.key),
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'captured':
        return Colors.green;
      case 'pending':
      case 'authorized':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatStatusName(String status) {
    return status.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }
}

class EarningsOverviewChart extends StatelessWidget {
  final Map<String, dynamic> monthlyEarnings;
  final double totalEarnings;

  const EarningsOverviewChart({
    Key? key,
    required this.monthlyEarnings,
    required this.totalEarnings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Earnings Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'R${totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A651),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildMonthlyChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    if (monthlyEarnings.isEmpty) {
      return const Center(
        child: Text('No monthly data available'),
      );
    }

    final sortedEntries = monthlyEarnings.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.value.toDouble(),
      );
    }).toList();

    final maxY = spots.isNotEmpty 
        ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
        : 100.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 25,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  'R${_formatNumber(value)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedEntries.length) {
                  final monthKey = sortedEntries[index].key;
                  final parts = monthKey.split('-');
                  if (parts.length == 2) {
                    final month = int.tryParse(parts[1]) ?? 1;
                    return Text(
                      DateFormat('MMM').format(DateTime(2024, month)),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (sortedEntries.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF00A651),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00A651).withOpacity(0.1),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class PerformanceInsightsCard extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final TaskerEarnings earnings;

  const PerformanceInsightsCard({
    Key? key,
    required this.analytics,
    required this.earnings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final successRate = (analytics['success_rate'] ?? 0.0).toDouble();
    final averagePayout = (analytics['average_payout'] ?? 0.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              'Task Completion Rate',
              '${((earnings.completedTasks / (earnings.totalTasks + 1)) * 100).toStringAsFixed(1)}%',
              Icons.task_alt,
              Colors.green,
              _getPerformanceMessage(earnings.completedTasks, earnings.totalTasks),
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              'Average Earning per Task',
              'R${earnings.averageEarning.toStringAsFixed(2)}',
              Icons.monetization_on,
              Colors.blue,
              _getEarningMessage(earnings.averageEarning),
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              'Payout Success Rate',
              '${successRate.toStringAsFixed(1)}%',
              Icons.check_circle,
              Colors.purple,
              _getPayoutMessage(successRate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String value,
    IconData icon,
    Color color,
    String message,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 20,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPerformanceMessage(int completed, int total) {
    final rate = (completed / (total + 1)) * 100;
    if (rate >= 90) return 'Excellent performance!';
    if (rate >= 75) return 'Good completion rate';
    if (rate >= 50) return 'Room for improvement';
    return 'Focus on completing more tasks';
  }

  String _getEarningMessage(double average) {
    if (average >= 200) return 'High-value task specialist';
    if (average >= 100) return 'Good earning potential';
    if (average >= 50) return 'Consider higher-value tasks';
    return 'Focus on premium opportunities';
  }

  String _getPayoutMessage(double rate) {
    if (rate >= 95) return 'Excellent payout reliability';
    if (rate >= 85) return 'Good payout success';
    if (rate >= 70) return 'Most payouts successful';
    return 'Contact support if issues persist';
  }
}

class PaymentMethodAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> methodDistribution;

  const PaymentMethodAnalysisCard({
    Key? key,
    required this.methodDistribution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payout Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PaymentMethodChart(data: methodDistribution),
            ),
          ],
        ),
      ),
    );
  }
}

class EarningPatternsCard extends StatelessWidget {
  final List<Map<String, dynamic>> earningsHistory;

  const EarningPatternsCard({
    Key? key,
    required this.earningsHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final patterns = _analyzePatterns();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earning Patterns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...patterns.map((pattern) => _buildPatternItem(pattern)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(Map<String, dynamic> pattern) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            pattern['icon'],
            color: pattern['color'],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  pattern['description'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _analyzePatterns() {
    if (earningsHistory.isEmpty) {
      return [
        {
          'title': 'No Data Yet',
          'description': 'Complete more tasks to see earning patterns',
          'icon': Icons.info,
          'color': Colors.grey,
        }
      ];
    }

    final patterns = <Map<String, dynamic>>[];

    // Analyze day of week patterns
    final dayOfWeekEarnings = <int, double>{};
    for (final earning in earningsHistory) {
      final date = earning['date'] as DateTime;
      final dayOfWeek = date.weekday;
      dayOfWeekEarnings[dayOfWeek] = 
          (dayOfWeekEarnings[dayOfWeek] ?? 0) + earning['net_earning'];
    }

    if (dayOfWeekEarnings.isNotEmpty) {
      final bestDay = dayOfWeekEarnings.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      patterns.add({
        'title': 'Best Earning Day',
        'description': '${_getDayName(bestDay.key)} - R${bestDay.value.toStringAsFixed(2)} total',
        'icon': Icons.calendar_today,
        'color': Colors.green,
      });
    }

    // Analyze category performance
    final categoryEarnings = <String, double>{};
    for (final earning in earningsHistory) {
      final category = earning['task_category'] as String;
      categoryEarnings[category] = 
          (categoryEarnings[category] ?? 0) + earning['net_earning'];
    }

    if (categoryEarnings.isNotEmpty) {
      final bestCategory = categoryEarnings.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      patterns.add({
        'title': 'Top Category',
        'description': '${bestCategory.key} - R${bestCategory.value.toStringAsFixed(2)} total',
        'icon': Icons.category,
        'color': Colors.blue,
      });
    }

    return patterns;
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek - 1];
  }
}

class GoalsAndProjectionsCard extends StatelessWidget {
  final TaskerEarnings earnings;
  final Map<String, dynamic> analytics;

  const GoalsAndProjectionsCard({
    Key? key,
    required this.earnings,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthlyProjection = _calculateMonthlyProjection();
    final nextMilestone = _getNextMilestone();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goals & Projections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalItem(
              'Monthly Projection',
              'R${monthlyProjection.toStringAsFixed(2)}',
              Icons.trending_up,
              Colors.green,
              'Based on current performance',
            ),
            const SizedBox(height: 12),
            _buildGoalItem(
              'Next Milestone',
              nextMilestone['title'],
              Icons.flag,
              Colors.orange,
              nextMilestone['description'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMonthlyProjection() {
    // Simple projection based on current average * estimated monthly tasks
    final avgEarning = earnings.averageEarning;
    final estimatedMonthlyTasks = earnings.completedTasks > 0 
        ? (earnings.completedTasks / 3) * 4 // Assuming 3 months of data, project for 4 weeks
        : 10; // Default estimate
    return avgEarning * estimatedMonthlyTasks;
  }

  Map<String, String> _getNextMilestone() {
    if (earnings.totalEarnings < 1000) {
      return {
        'title': 'R1,000 Total Earnings',
        'description': 'R${(1000 - earnings.totalEarnings).toStringAsFixed(2)} to go',
      };
    } else if (earnings.totalEarnings < 5000) {
      return {
        'title': 'R5,000 Total Earnings',
        'description': 'R${(5000 - earnings.totalEarnings).toStringAsFixed(2)} to go',
      };
    } else if (earnings.completedTasks < 50) {
      return {
        'title': '50 Completed Tasks',
        'description': '${50 - earnings.completedTasks} tasks to go',
      };
    } else {
      return {
        'title': 'Top Performer Status',
        'description': 'Keep up the excellent work!',
      };
    }
  }
}

// Additional helper widgets for better UX

class EarningsFilterHeader extends StatefulWidget {
  final double totalEarnings;
  final double availableEarnings;
  final double pendingEarnings;
  final Function(Map<String, dynamic>) onFilterChanged;

  const EarningsFilterHeader({
    Key? key,
    required this.totalEarnings,
    required this.availableEarnings,
    required this.pendingEarnings,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<EarningsFilterHeader> createState() => _EarningsFilterHeaderState();
}

class _EarningsFilterHeaderState extends State<EarningsFilterHeader> {
  String _selectedPeriod = 'all';
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Summary row
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total',
                  'R${widget.totalEarnings.toStringAsFixed(2)}',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Available',
                  'R${widget.availableEarnings.toStringAsFixed(2)}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Pending',
                  'R${widget.pendingEarnings.toStringAsFixed(2)}',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Time')),
                    DropdownMenuItem(value: '7days', child: Text('Last 7 Days')),
                    DropdownMenuItem(value: '30days', child: Text('Last 30 Days')),
                    DropdownMenuItem(value: '90days', child: Text('Last 90 Days')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPeriod = value!);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'available', child: Text('Available')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _applyFilters() {
    DateTime? startDate;
    DateTime? endDate = DateTime.now();

    switch (_selectedPeriod) {
      case '7days':
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case '30days':
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case '90days':
        startDate = DateTime.now().subtract(const Duration(days: 90));
        break;
      case 'all':
      default:
        startDate = null;
        endDate = null;
        break;
    }

    widget.onFilterChanged({
      'period': _selectedPeriod,
      'status': _selectedStatus,
      'startDate': startDate,
      'endDate': endDate,
    });
  }
}

class EarningHistoryCard extends StatelessWidget {
  final Map<String, dynamic> earning;
  final VoidCallback onTap;

  const EarningHistoryCard({
    Key? key,
    required this.earning,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAvailable = earning['is_available'] ?? false;
    final escrowStatus = earning['escrow_status'] ?? 'unknown';

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          earning['task_title'] ?? 'Task Completed',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          earning['task_category'] ?? 'General',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R${earning['net_earning'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAvailable ? 'Available' : 'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isAvailable ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(earning['date']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Gross: R${earning['gross_amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Fee: R${earning['platform_fee'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PayoutSummaryHeader extends StatelessWidget {
  final double availableAmount;
  final double pendingAmount;
  final double lifetimePayouts;
  final VoidCallback onRequestPayout;

  const PayoutSummaryHeader({
    Key? key,
    required this.availableAmount,
    required this.pendingAmount,
    required this.lifetimePayouts,
    required this.onRequestPayout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main payout card
          Card(
            elevation: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00A651),
                    const Color(0xFF00A651).withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Available for Payout',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R${availableAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: availableAmount > 0 ? onRequestPayout : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00A651),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        availableAmount > 0 
                            ? 'Request Payout'
                            : 'No Funds Available',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Summary stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  'R${pendingAmount.toStringAsFixed(2)}',
                  'In escrow/processing',
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Lifetime Payouts',
                  'R${lifetimePayouts.toStringAsFixed(2)}',
                  'Total withdrawn',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PayoutHistoryCard extends StatelessWidget {
  final PayoutModel payout;
  final VoidCallback onTap;
  final VoidCallback? onRetry;

  const PayoutHistoryCard({
    Key? key,
    required this.payout,
    required this.onTap,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getStatusColor().withOpacity(0.1),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payout #${payout.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${payout.bankAccount.bankName} • ${payout.bankAccount.maskedAccountNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R${payout.netAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          payout.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Requested: ${DateFormat('MMM dd, yyyy HH:mm').format(payout.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (payout.processingFee > 0)
                    Text(
                      'Fee: R${payout.processingFee.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              if (payout.status == PayoutStatus.failed && onRetry != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Payout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
              if (payout.failureReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          payout.failureReason!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (payout.status) {
      case PayoutStatus.pending:
        return Colors.orange;
      case PayoutStatus.processing:
        return Colors.blue;
      case PayoutStatus.completed:
        return Colors.green;
      case PayoutStatus.failed:
        return Colors.red;
      case PayoutStatus.cancelled:
        return Colors.grey;
      case PayoutStatus.on_hold:
        return Colors.purple;
      case PayoutStatus.returned:
        return Colors.brown;
    }
  }

  IconData _getStatusIcon() {
    switch (payout.status) {
      case PayoutStatus.pending:
        return Icons.hourglass_empty;
      case PayoutStatus.processing:
        return Icons.sync;
      case PayoutStatus.completed:
        return Icons.check_circle;
      case PayoutStatus.failed:
        return Icons.error;
      case PayoutStatus.cancelled:
        return Icons.cancel;
      case PayoutStatus.on_hold:
        return Icons.pause_circle;
      case PayoutStatus.returned:
        return Icons.undo;
    }
  }
}

// Export and help dialogs
class ExportDataDialog extends StatelessWidget {
  const ExportDataDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Data'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.table_chart),
            title: Text('Earnings CSV'),
            subtitle: Text('Export all earnings data'),
          ),
          ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('Tax Report'),
            subtitle: Text('Year-end tax summary'),
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Payout History'),
            subtitle: Text('All payout transactions'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Implement export logic
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}

class EarningsHelpDialog extends StatelessWidget {
  const EarningsHelpDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Help & Support'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How Earnings Work',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Earnings are held in escrow for 24 hours after task completion'),
            Text('• Available earnings can be withdrawn anytime'),
            Text('• Minimum payout amount is R50.00'),
            SizedBox(height: 16),
            Text(
              'Payout Methods',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Bank Transfer: 1-3 business days (free)'),
            Text('• Instant EFT: Within 2 hours (2% fee)'),
            SizedBox(height: 16),
            Text(
              'Need Help?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Contact support@taskers.co.za for assistance'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Open support chat or email
          },
          child: const Text('Contact Support'),
        ),
      ],
    );
  }
}

class TaxInformationDialog extends StatelessWidget {
  final TaskerEarnings earnings;
  final double yearlyEarnings;

  const TaxInformationDialog({
    Key? key,
    required this.earnings,
    required this.yearlyEarnings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tax Information'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${DateTime.now().year} Tax Year',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTaxRow('Total Earnings', 'R${yearlyEarnings.toStringAsFixed(2)}'),
            _buildTaxRow('Estimated Tax (20%)', 'R${(yearlyEarnings * 0.2).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text(
              'Important Notes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Keep records of all earnings and expenses'),
            const Text('• Consult a tax professional for advice'),
            const Text('• Register for tax if earning over R1,000,000/year'),
            const Text('• Consider provisional tax if applicable'),
            const SizedBox(height: 16),
            const Text(
              'This is for informational purposes only. Consult a qualified tax advisor.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Generate tax report
          },
          child: const Text('Generate Report'),
        ),
      ],
    );
  }

  Widget _buildTaxRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}