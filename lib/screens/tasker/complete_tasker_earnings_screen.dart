import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:taskers/services/complete_payout_service.dart';
import '../../models/payout_model.dart';
import '../../services/complete_payout_service.dart';
import '../../widgets/earnings_widgets.dart';

class CompleteTaskerEarningsScreen extends StatefulWidget {
  const CompleteTaskerEarningsScreen({Key? key}) : super(key: key);

  @override
  State<CompleteTaskerEarningsScreen> createState() =>
      _CompleteTaskerEarningsScreenState();
}

class _CompleteTaskerEarningsScreenState
    extends State<CompleteTaskerEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  TaskerEarnings? _earnings;
  List<PayoutModel> _payoutHistory = [];
  List<Map<String, dynamic>> _earningsHistory = [];
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final results = await Future.wait([
        CompletePayoutService.getTaskerEarnings(userId),
        CompletePayoutService.getTaskerPayouts(taskerId: userId),
        CompletePayoutService.getDetailedEarningsHistory(taskerId: userId),
        CompletePayoutService.getPayoutAnalytics(userId),
      ]);

      setState(() {
        _earnings = results[0] as TaskerEarnings;
        _payoutHistory = results[1] as List<PayoutModel>;
        _earningsHistory = results[2] as List<Map<String, dynamic>>;
        _analytics = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading earnings data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.history), text: 'Earnings'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Payouts'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportData();
                  break;
                case 'help':
                  _showHelpDialog();
                  break;
                case 'tax_info':
                  _showTaxInfoDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tax_info',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long),
                    SizedBox(width: 8),
                    Text('Tax Information'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help),
                    SizedBox(width: 8),
                    Text('Help & Support'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00A651)),
                  SizedBox(height: 16),
                  Text('Loading your earnings...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildEarningsTab(),
                _buildPayoutsTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton:
          _earnings != null && _earnings!.availableEarnings > 0
              ? FloatingActionButton.extended(
                  onPressed: _requestPayout,
                  backgroundColor: const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Request Payout'),
                )
              : null,
    );
  }

  Widget _buildOverviewTab() {
    if (_earnings == null) {
      return const Center(child: Text('No earnings data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Summary Cards
            EarningsSummaryCards(earnings: _earnings!),

            const SizedBox(height: 24),

            // Quick Actions
            QuickActionsCard(
              availableEarnings: _earnings!.availableEarnings,
              onRequestPayout: _requestPayout,
              onAddBankAccount: _addBankAccount,
              onViewHistory: () => _tabController.animateTo(1),
            ),

            const SizedBox(height: 24),

            // Performance Metrics
            PerformanceMetricsCard(
              earnings: _earnings!,
              analytics: _analytics,
            ),

            const SizedBox(height: 24),

            // Recent Activity
            RecentActivityCard(
              earningsHistory: _earningsHistory.take(5).toList(),
              payoutHistory: _payoutHistory.take(3).toList(),
              onViewAllEarnings: () => _tabController.animateTo(1),
              onViewAllPayouts: () => _tabController.animateTo(2),
            ),

            const SizedBox(height: 24),

            // Tips and Insights
            TipsAndInsightsCard(earnings: _earnings!),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsTab() {
    return Column(
      children: [
        // Filter and summary header
        EarningsFilterHeader(
          totalEarnings: _earnings?.totalEarnings ?? 0.0,
          availableEarnings: _earnings?.availableEarnings ?? 0.0,
          pendingEarnings: _earnings?.pendingEarnings ?? 0.0,
          onFilterChanged: _filterEarnings,
        ),

        // Earnings list
        Expanded(
          child: _earningsHistory.isEmpty
              ? const EmptyEarningsState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _earningsHistory.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final earning = _earningsHistory[index];
                    return EarningHistoryCard(
                      earning: earning,
                      onTap: () => _showEarningDetails(earning),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPayoutsTab() {
    return Column(
      children: [
        // Payout summary and quick action
        PayoutSummaryHeader(
          availableAmount: _earnings?.availableEarnings ?? 0.0,
          pendingAmount: _earnings?.pendingPayouts ?? 0.0,
          lifetimePayouts: _earnings?.lifetimePayouts ?? 0.0,
          onRequestPayout: _requestPayout,
        ),

        // Payout history
        Expanded(
          child: _payoutHistory.isEmpty
              ? const EmptyPayoutsState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payoutHistory.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final payout = _payoutHistory[index];
                    return PayoutHistoryCard(
                      payout: payout,
                      onTap: () => _showPayoutDetails(payout),
                      onRetry: payout.status == PayoutStatus.failed
                          ? () => _retryPayout(payout)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings Overview Chart
          EarningsOverviewChart(
            monthlyEarnings: _analytics['monthly_payouts'] ?? {},
            totalEarnings: _earnings?.totalEarnings ?? 0.0,
          ),

          const SizedBox(height: 24),

          // Performance Insights
          PerformanceInsightsCard(
            analytics: _analytics,
            earnings: _earnings!,
          ),

          const SizedBox(height: 24),

          // Payment Method Analysis
          PaymentMethodAnalysisCard(
            methodDistribution: _analytics['method_distribution'] ?? {},
          ),

          const SizedBox(height: 24),

          // Earning Patterns
          EarningPatternsCard(
            earningsHistory: _earningsHistory,
          ),

          const SizedBox(height: 24),

          // Goals and Projections
          GoalsAndProjectionsCard(
            earnings: _earnings!,
            analytics: _analytics,
          ),
        ],
      ),
    );
  }

  // Action methods
  void _requestPayout() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PayoutRequestBottomSheet(
        availableAmount: _earnings?.availableEarnings ?? 0.0,
        onPayoutRequested: () {
          _loadAllData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payout request submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _addBankAccount() {
    Navigator.of(context).pushNamed('/add-bank-account').then((_) {
      // Refresh data after adding bank account
      _loadAllData();
    });
  }

  void _filterEarnings(Map<String, dynamic> filters) async {
    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final filteredHistory =
          await CompletePayoutService.getDetailedEarningsHistory(
        taskerId: userId,
        startDate: filters['startDate'],
        endDate: filters['endDate'],
        limit: filters['limit'] ?? 100,
      );

      setState(() {
        _earningsHistory = filteredHistory;
        _isLoading = false;
      });
    } catch (e) {
      print('Error filtering earnings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showEarningDetails(Map<String, dynamic> earning) {
    showDialog(
      context: context,
      builder: (context) => EarningDetailsDialog(earning: earning),
    );
  }

  void _showPayoutDetails(PayoutModel payout) {
    showDialog(
      context: context,
      builder: (context) => PayoutDetailsDialog(payout: payout),
    );
  }

  void _retryPayout(PayoutModel payout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Payout'),
        content: Text(
          'Retry payout of R${payout.amount.toStringAsFixed(2)}?\n\n'
          'The previous attempt failed: ${payout.failureReason ?? "Unknown error"}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Request new payout with same details
      final result = await CompletePayoutService.requestPayout(
        taskerId: FirebaseAuth.instance.currentUser!.uid,
        amount: payout.amount,
        bankAccount: payout.bankAccount,
        method: payout.method,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success']
                  ? 'Payout retry submitted successfully'
                  : 'Error: ${result['error']}',
            ),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        if (result['success']) {
          _loadAllData();
        }
      }
    }
  }

  void _exportData() async {
    showDialog(
      context: context,
      builder: (context) => const ExportDataDialog(),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => const EarningsHelpDialog(),
    );
  }

  void _showTaxInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => TaxInformationDialog(
        earnings: _earnings!,
        yearlyEarnings: _calculateYearlyEarnings(),
      ),
    );
  }

  double _calculateYearlyEarnings() {
    final currentYear = DateTime.now().year;
    return _earningsHistory
        .where((earning) => earning['date'].year == currentYear)
        .fold(0.0, (sum, earning) => sum + earning['net_earning']);
  }
}
