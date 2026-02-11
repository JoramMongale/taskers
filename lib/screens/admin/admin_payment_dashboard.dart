// lib/screens/admin/admin_payment_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/payment_service.dart';
import '../../services/escrow_automation_service.dart';
import '../../widgets/chart_widgets.dart';

class AdminPaymentDashboard extends StatefulWidget {
  const AdminPaymentDashboard({Key? key}) : super(key: key);

  @override
  State<AdminPaymentDashboard> createState() => _AdminPaymentDashboardState();
}

class _AdminPaymentDashboardState extends State<AdminPaymentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<TransactionModel> _recentTransactions = [];
  String _selectedPeriod = '7days';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load various dashboard metrics
      final results = await Future.wait([
        _getPaymentSummary(),
        _getEscrowSummary(),
        _getRecentTransactions(),
        _getPaymentAnalytics(),
      ]);

      setState(() {
        _dashboardData = {
          'payment_summary': results[0],
          'escrow_summary': results[1],
          'recent_transactions': results[2],
          'analytics': results[3],
        };
        _recentTransactions = results[2] as List<TransactionModel>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getPaymentSummary() async {
    // This would typically call your backend API
    return PaymentService.getPaymentSummary(_selectedPeriod);
  }

  Future<Map<String, dynamic>> _getEscrowSummary() async {
    return EscrowAutomationService.getEscrowSummary();
  }

  Future<List<TransactionModel>> _getRecentTransactions() async {
    return PaymentService.getRecentTransactions(limit: 20);
  }

  Future<Map<String, dynamic>> _getPaymentAnalytics() async {
    return PaymentService.getPaymentAnalytics(_selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Dashboard'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'Escrow'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (period) {
              setState(() => _selectedPeriod = period);
              _loadDashboardData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '24h', child: Text('Last 24 Hours')),
              const PopupMenuItem(value: '7days', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30days', child: Text('Last 30 Days')),
              const PopupMenuItem(value: '90days', child: Text('Last 90 Days')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTransactionsTab(),
                _buildEscrowTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final paymentSummary = _dashboardData['payment_summary'] ?? {};
    final escrowSummary = _dashboardData['escrow_summary'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryCard(
                  title: 'Total Revenue',
                  value:
                      'R${(paymentSummary['total_revenue'] ?? 0.0).toStringAsFixed(2)}',
                  subtitle: 'Platform earnings',
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                ),
                _buildSummaryCard(
                  title: 'Transactions',
                  value: '${paymentSummary['total_transactions'] ?? 0}',
                  subtitle: 'Processed',
                  icon: Icons.swap_horiz,
                  color: Colors.blue,
                ),
                _buildSummaryCard(
                  title: 'Held in Escrow',
                  value:
                      'R${(escrowSummary['total_held'] ?? 0.0).toStringAsFixed(2)}',
                  subtitle:
                      '${escrowSummary['transactions_held'] ?? 0} transactions',
                  icon: Icons.lock,
                  color: Colors.orange,
                ),
                _buildSummaryCard(
                  title: 'Success Rate',
                  value:
                      '${(paymentSummary['success_rate'] ?? 0.0).toStringAsFixed(1)}%',
                  subtitle: 'Payment success',
                  icon: Icons.check_circle,
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          'Pending Releases',
                          '${escrowSummary['pending_auto_releases'] ?? 0}',
                          Icons.schedule,
                          () => _showPendingReleases(),
                        ),
                        _buildActionButton(
                          'Failed Payments',
                          '${paymentSummary['failed_count'] ?? 0}',
                          Icons.error,
                          () => _showFailedPayments(),
                        ),
                        _buildActionButton(
                          'Refund Requests',
                          '${paymentSummary['refund_requests'] ?? 0}',
                          Icons.undo,
                          () => _showRefundRequests(),
                        ),
                        _buildActionButton(
                          'Export Data',
                          '',
                          Icons.download,
                          () => _exportPaymentData(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Activity
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ..._recentTransactions.take(5).map(
                          (transaction) =>
                              _buildTransactionListTile(transaction),
                        ),
                    if (_recentTransactions.length > 5)
                      TextButton(
                        onPressed: () => _tabController.animateTo(1),
                        child: const Text('View All Transactions'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedPeriod,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    );
  }

  Widget _buildActionButton(
    String title,
    String badge,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(title),
            if (badge.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        // Filter and search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (query) {
                    // Implement search functionality
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: 'all',
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                      value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                ],
                onChanged: (value) {
                  // Implement filter functionality
                },
              ),
            ],
          ),
        ),
        // Transactions list
        Expanded(
          child: ListView.builder(
            itemCount: _recentTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _recentTransactions[index];
              return _buildTransactionListTile(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionListTile(TransactionModel transaction) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(transaction.status).withOpacity(0.1),
        child: Icon(
          _getStatusIcon(transaction.status),
          color: _getStatusColor(transaction.status),
        ),
      ),
      title: Text('Task #${transaction.taskId.substring(0, 8)}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('R${transaction.totalAmount.toStringAsFixed(2)}'),
          Text(
            DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(transaction.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              transaction.status.name.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(transaction.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (transaction.escrowStatus != EscrowStatus.none)
            Text(
              transaction.escrowStatus.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
        ],
      ),
      onTap: () => _showTransactionDetails(transaction),
    );
  }

  Widget _buildEscrowTab() {
    final escrowSummary = _dashboardData['escrow_summary'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Escrow Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildSummaryCard(
                title: 'Total Held',
                value:
                    'R${(escrowSummary['total_held'] ?? 0.0).toStringAsFixed(2)}',
                subtitle:
                    '${escrowSummary['transactions_held'] ?? 0} transactions',
                icon: Icons.lock,
                color: Colors.orange,
              ),
              _buildSummaryCard(
                title: 'Pending Releases',
                value: '${escrowSummary['pending_auto_releases'] ?? 0}',
                subtitle: 'Auto-release ready',
                icon: Icons.schedule,
                color: Colors.blue,
              ),
              _buildSummaryCard(
                title: 'Released (7 days)',
                value:
                    'R${(escrowSummary['recent_released_7days'] ?? 0.0).toStringAsFixed(2)}',
                subtitle:
                    '${escrowSummary['recent_releases_count'] ?? 0} releases',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildSummaryCard(
                title: 'Automation Status',
                value: 'Active',
                subtitle: 'Last check: Now',
                icon: Icons.auto_mode,
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Manual Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual Escrow Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _triggerManualEscrowCheck(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Check Pending Releases'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBulkEscrowActions(),
                          icon: const Icon(Icons.batch_prediction),
                          label: const Text('Bulk Actions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Escrow Activity Log
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Escrow Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // This would show recent escrow logs
                  _buildEscrowActivityList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final analytics = _dashboardData['analytics'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Method Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Methods',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PaymentMethodChart(
                      data: analytics['payment_methods'] ?? {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Revenue Trends
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Trends',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: RevenueTrendChart(
                      data: analytics['revenue_trends'] ?? [],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Transaction Status Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: TransactionStatusChart(
                      data: analytics['transaction_status'] ?? {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowActivityList() {
    // This would typically load from Firebase
    return Column(
      children: [
        _buildEscrowActivityItem(
          'Auto-release',
          'Task #abc123 - R150.00 released',
          '2 hours ago',
          Icons.auto_mode,
          Colors.green,
        ),
        _buildEscrowActivityItem(
          'Manual release',
          'Task #def456 - R75.00 released by admin',
          '5 hours ago',
          Icons.person,
          Colors.blue,
        ),
        _buildEscrowActivityItem(
          'Escrow held',
          'Task #ghi789 - R200.00 held in escrow',
          '1 day ago',
          Icons.lock,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildEscrowActivityItem(
    String action,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(action),
      subtitle: Text(description),
      trailing: Text(
        time,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.authorized:
        return Colors.blue;
      case TransactionStatus.captured:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.refunded:
        return Colors.purple;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.hourglass_empty;
      case TransactionStatus.authorized:
        return Icons.check_circle_outline;
      case TransactionStatus.captured:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.error;
      case TransactionStatus.refunded:
        return Icons.undo;
      case TransactionStatus.cancelled:
        return Icons.cancel;
    }
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailsDialog(transaction: transaction),
    );
  }

  void _showPendingReleases() {
    // Navigate to pending releases screen
    Navigator.of(context).pushNamed('/admin/pending-releases');
  }

  void _showFailedPayments() {
    // Navigate to failed payments screen
    Navigator.of(context).pushNamed('/admin/failed-payments');
  }

  void _showRefundRequests() {
    // Navigate to refund requests screen
    Navigator.of(context).pushNamed('/admin/refund-requests');
  }

  void _exportPaymentData() async {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting payment data...'),
      ),
    );

    // This would typically generate and download a CSV/Excel file
  }

  void _triggerManualEscrowCheck() async {
    // Trigger manual escrow automation check
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking for pending escrow releases...'),
      ),
    );

    // This would call the escrow automation service
    await EscrowAutomationService._checkPendingReleases();
    _loadDashboardData();
  }

  void _showBulkEscrowActions() {
    showDialog(
      context: context,
      builder: (context) => const BulkEscrowActionsDialog(),
    );
  }
}

// Transaction Details Dialog
class TransactionDetailsDialog extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsDialog({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Transaction #${transaction.id.substring(0, 8)}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Task ID', transaction.taskId),
            _buildDetailRow(
                'Amount', 'R${transaction.totalAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Tasker Amount',
                'R${transaction.taskerAmount.toStringAsFixed(2)}'),
            _buildDetailRow(
                'Service Fee', 'R${transaction.serviceFee.toStringAsFixed(2)}'),
            _buildDetailRow('Status', transaction.status.name.toUpperCase()),
            _buildDetailRow(
                'Escrow Status', transaction.escrowStatus.name.toUpperCase()),
            _buildDetailRow('Payment Method', transaction.paymentMethod),
            _buildDetailRow('Gateway', transaction.gateway),
            if (transaction.gatewayTransactionId != null)
              _buildDetailRow('Gateway ID', transaction.gatewayTransactionId!),
            _buildDetailRow('Created',
                DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt)),
            if (transaction.authorizedAt != null)
              _buildDetailRow(
                  'Authorized',
                  DateFormat('MMM dd, yyyy HH:mm')
                      .format(transaction.authorizedAt!)),
            if (transaction.capturedAt != null)
              _buildDetailRow(
                  'Captured',
                  DateFormat('MMM dd, yyyy HH:mm')
                      .format(transaction.capturedAt!)),
            if (transaction.releasedAt != null)
              _buildDetailRow(
                  'Released',
                  DateFormat('MMM dd, yyyy HH:mm')
                      .format(transaction.releasedAt!)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (transaction.escrowStatus == EscrowStatus.held)
          ElevatedButton(
            onPressed: () => _manualEscrowRelease(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Release Escrow'),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _manualEscrowRelease(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Escrow'),
        content: Text(
          'Release R${transaction.taskerAmount.toStringAsFixed(2)} to the Tasker?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Release'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Process manual release
      final result = await EscrowAutomationService.manualEscrowRelease(
        taskId: transaction.taskId,
        adminId: FirebaseAuth.instance.currentUser?.uid ?? '',
        reason: 'manual_admin_release',
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close transaction details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success']
                  ? 'Escrow released successfully'
                  : 'Error: ${result['error']}',
            ),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

// Bulk Escrow Actions Dialog
class BulkEscrowActionsDialog extends StatelessWidget {
  const BulkEscrowActionsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Escrow Actions'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.auto_mode, color: Colors.blue),
            title: const Text('Release All Pending'),
            subtitle: const Text('Auto-release all eligible escrows'),
            onTap: () => _bulkAutoRelease(context),
          ),
          ListTile(
            leading: const Icon(Icons.schedule, color: Colors.orange),
            title: const Text('View Pending'),
            subtitle: const Text('Show all pending releases'),
            onTap: () => _viewPending(context),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.green),
            title: const Text('Force Check'),
            subtitle: const Text('Run escrow automation now'),
            onTap: () => _forceCheck(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _bulkAutoRelease(BuildContext context) {
    // Implement bulk auto-release
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing bulk auto-release...')),
    );
  }

  void _viewPending(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed('/admin/pending-escrow');
  }

  void _forceCheck(BuildContext context) async {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Running escrow automation check...')),
    );
    await EscrowAutomationService._checkPendingReleases();
  }
}
