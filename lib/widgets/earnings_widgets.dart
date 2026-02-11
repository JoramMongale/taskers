import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payout_model.dart';

class EarningsSummaryCards extends StatelessWidget {
  final TaskerEarnings earnings;

  const EarningsSummaryCards({Key? key, required this.earnings})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildEarningsCard(
          'Available Now',
          'R${earnings.availableEarnings.toStringAsFixed(2)}',
          'Ready to withdraw',
          Icons.account_balance_wallet,
          Colors.green,
          isHighlighted: earnings.availableEarnings > 0,
        ),
        _buildEarningsCard(
          'Pending Release',
          'R${earnings.pendingEarnings.toStringAsFixed(2)}',
          'In 24hr escrow',
          Icons.hourglass_empty,
          Colors.orange,
        ),
        _buildEarningsCard(
          'Total Earned',
          'R${earnings.totalEarnings.toStringAsFixed(2)}',
          'All time earnings',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildEarningsCard(
          'This Month',
          'R${_calculateCurrentMonthEarnings().toStringAsFixed(2)}',
          DateFormat('MMMM yyyy').format(DateTime.now()),
          Icons.calendar_month,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildEarningsCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Card(
      elevation: isHighlighted ? 4 : 2,
      child: Container(
        decoration: isHighlighted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  if (isHighlighted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '💰',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? color : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateCurrentMonthEarnings() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    // This would calculate from earnings history in real implementation
    return earnings.totalEarnings * 0.2; // Placeholder
  }
}

class QuickActionsCard extends StatelessWidget {
  final double availableEarnings;
  final VoidCallback onRequestPayout;
  final VoidCallback onAddBankAccount;
  final VoidCallback onViewHistory;

  const QuickActionsCard({
    Key? key,
    required this.availableEarnings,
    required this.onRequestPayout,
    required this.onAddBankAccount,
    required this.onViewHistory,
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
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Request Payout',
                    Icons.send,
                    availableEarnings > 0 ? onRequestPayout : null,
                    isPrimary: true,
                    subtitle: availableEarnings > 0
                        ? 'R${availableEarnings.toStringAsFixed(2)} available'
                        : 'No funds available',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Add Bank Account',
                    Icons.add_card,
                    onAddBankAccount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'View History',
                    Icons.history,
                    onViewHistory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Export Data',
                    Icons.download,
                    () {}, // Would implement export
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback? onTap, {
    bool isPrimary = false,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPrimary
              ? (onTap != null ? const Color(0xFF00A651) : Colors.grey.shade300)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? (onTap != null ? const Color(0xFF00A651) : Colors.grey)
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPrimary
                  ? (onTap != null ? Colors.white : Colors.grey)
                  : (onTap != null ? Colors.black87 : Colors.grey),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isPrimary
                    ? (onTap != null ? Colors.white : Colors.grey)
                    : (onTap != null ? Colors.black87 : Colors.grey),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isPrimary
                      ? (onTap != null ? Colors.white70 : Colors.grey)
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PerformanceMetricsCard extends StatelessWidget {
  final TaskerEarnings earnings;
  final Map<String, dynamic> analytics;

  const PerformanceMetricsCard({
    Key? key,
    required this.earnings,
    required this.analytics,
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
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Tasks Completed',
                    '${earnings.completedTasks}',
                    Icons.task_alt,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Average Earning',
                    'R${earnings.averageEarning.toStringAsFixed(0)}',
                    Icons.bar_chart,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Payout Success',
                    '${successRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Avg Payout',
                    'R${averagePayout.toStringAsFixed(0)}',
                    Icons.payments,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> earningsHistory;
  final List<PayoutModel> payoutHistory;
  final VoidCallback onViewAllEarnings;
  final VoidCallback onViewAllPayouts;

  const RecentActivityCard({
    Key? key,
    required this.earningsHistory,
    required this.payoutHistory,
    required this.onViewAllEarnings,
    required this.onViewAllPayouts,
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
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: onViewAllEarnings,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recent earnings
            if (earningsHistory.isNotEmpty) ...[
              const Text(
                'Recent Earnings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ...earningsHistory.map((earning) => _buildEarningItem(earning)),
            ],

            if (earningsHistory.isNotEmpty && payoutHistory.isNotEmpty)
              const Divider(height: 24),

            // Recent payouts
            if (payoutHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Payouts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAllPayouts,
                    child:
                        const Text('View All', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...payoutHistory.map((payout) => _buildPayoutItem(payout)),
            ],

            if (earningsHistory.isEmpty && payoutHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningItem(Map<String, dynamic> earning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green.withOpacity(0.1),
            child: const Icon(Icons.add, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earning['task_title'] ?? 'Task Completed',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM dd, HH:mm').format(earning['date']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+R${earning['net_earning'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: earning['is_available']
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  earning['is_available'] ? 'Available' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        earning['is_available'] ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutItem(PayoutModel payout) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                _getPayoutStatusColor(payout.status).withOpacity(0.1),
            child: Icon(
              _getPayoutStatusIcon(payout.status),
              color: _getPayoutStatusColor(payout.status),
              size: 16,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, HH:mm').format(payout.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPayoutStatusColor(payout.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payout.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getPayoutStatusColor(payout.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPayoutStatusColor(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.pending:
        return Colors.orange;
      case PayoutStatus.processing:
        return Colors.blue;
      case PayoutStatus.completed:
        return Colors.green;
      case PayoutStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPayoutStatusIcon(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.pending:
        return Icons.hourglass_empty;
      case PayoutStatus.processing:
        return Icons.sync;
      case PayoutStatus.completed:
        return Icons.check_circle;
      case PayoutStatus.failed:
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}

class TipsAndInsightsCard extends StatelessWidget {
  final TaskerEarnings earnings;

  const TipsAndInsightsCard({Key? key, required this.earnings})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tips = _generateTips();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Tips & Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => _buildTipItem(tip)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateTips() {
    final tips = <Map<String, dynamic>>[];

    if (earnings.availableEarnings >= 500) {
      tips.add({
        'title': 'Ready for Payout!',
        'description':
            'You have R${earnings.availableEarnings.toStringAsFixed(2)} ready to withdraw.',
        'icon': Icons.account_balance_wallet,
        'color': Colors.green,
      });
    }

    if (earnings.averageEarning < 100) {
      tips.add({
        'title': 'Increase Your Earnings',
        'description':
            'Consider taking on higher-value tasks to boost your average earning.',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      });
    }

    if (earnings.completedTasks < 10) {
      tips.add({
        'title': 'Build Your Reputation',
        'description':
            'Complete more tasks to build trust and attract premium clients.',
        'icon': Icons.star,
        'color': Colors.purple,
      });
    }

    return tips;
  }

  Widget _buildTipItem(Map<String, dynamic> tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: tip['color'].withOpacity(0.1),
            child: Icon(
              tip['icon'],
              color: tip['color'],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip['description'],
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
}
