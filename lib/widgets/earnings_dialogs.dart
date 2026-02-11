import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/payout_model.dart';
import '../services/complete_payout_service.dart';

class PayoutRequestBottomSheet extends StatefulWidget {
  final double availableAmount;
  final VoidCallback onPayoutRequested;

  const PayoutRequestBottomSheet({
    Key? key,
    required this.availableAmount,
    required this.onPayoutRequested,
  }) : super(key: key);

  @override
  State<PayoutRequestBottomSheet> createState() =>
      _PayoutRequestBottomSheetState();
}

class _PayoutRequestBottomSheetState extends State<PayoutRequestBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  BankAccount? _selectedBankAccount;
  PayoutMethod _selectedMethod = PayoutMethod.bank_transfer;
  bool _isInstant = false;
  bool _isLoading = false;
  List<BankAccount> _bankAccounts = [];
  Map<String, double>? _calculatedFees;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.availableAmount.toStringAsFixed(2);
    _loadBankAccounts();
    _calculateFees();
  }

  Future<void> _loadBankAccounts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final accounts = await CompletePayoutService.getUserBankAccounts(userId);
      setState(() {
        _bankAccounts = accounts;
        if (accounts.isNotEmpty) {
          _selectedBankAccount = accounts.firstWhere(
            (account) => account.isDefault,
            orElse: () => accounts.first,
          );
        }
      });
    }
  }

  void _calculateFees() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount > 0) {
      final fees = CompletePayoutService._calculatePayoutFees(
        amount,
        _selectedMethod,
        _isInstant,
      );
      setState(() {
        _calculatedFees = fees;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Request Payout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Available amount display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Available for Payout',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'R${widget.availableAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount input
                    const Text(
                      'Payout Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: 'R',
                        border: OutlineInputBorder(),
                        hintText: '0.00',
                        helperText: 'Minimum: R50.00',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (amount < 50.0) {
                          return 'Minimum payout amount is R50.00';
                        }
                        if (amount > widget.availableAmount) {
                          return 'Amount exceeds available balance';
                        }
                        return null;
                      },
                      onChanged: (value) => _calculateFees(),
                    ),

                    const SizedBox(height: 24),

                    // Payout method selection
                    const Text(
                      'Payout Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: PayoutMethod.values.map((method) {
                        return _buildMethodTile(method);
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Bank account selection
                    const Text(
                      'Bank Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_bankAccounts.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: _bankAccounts.map((account) {
                            return _buildBankAccountTile(account);
                          }).toList(),
                        ),
                      )
                    else
                      _buildNoBankAccountsState(),

                    const SizedBox(height: 24),

                    // Instant payout option (if applicable)
                    if (_selectedMethod == PayoutMethod.bank_transfer)
                      Card(
                        child: SwitchListTile(
                          title: const Text('Instant Payout'),
                          subtitle:
                              const Text('Receive funds within 30 minutes'),
                          value: _isInstant,
                          onChanged: (value) {
                            setState(() {
                              _isInstant = value;
                            });
                            _calculateFees();
                          },
                          activeColor: const Color(0xFF00A651),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Fee breakdown
                    if (_calculatedFees != null) _buildFeeBreakdown(),

                    const SizedBox(height: 24),

                    // Processing information
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Processing Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getProcessingInfo(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedBankAccount != null && !_isLoading
                    ? _submitPayoutRequest
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Request Payout${_calculatedFees != null ? " (R${_calculatedFees!['net_amount']!.toStringAsFixed(2)})" : ""}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(PayoutMethod method) {
    final isSelected = _selectedMethod == method;
    final isEnabled = _isMethodEnabled(method);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isEnabled
            ? () {
                setState(() {
                  _selectedMethod = method;
                  if (method != PayoutMethod.bank_transfer) {
                    _isInstant =
                        false; // Reset instant option for other methods
                  }
                });
                _calculateFees();
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF00A651) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? const Color(0xFF00A651).withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              Icon(
                _getMethodIcon(method),
                color: isEnabled
                    ? (isSelected ? const Color(0xFF00A651) : Colors.grey[600])
                    : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMethodName(method),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isEnabled ? Colors.black87 : Colors.grey[400],
                      ),
                    ),
                    Text(
                      _getMethodDescription(method),
                      style: TextStyle(
                        fontSize: 12,
                        color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF00A651)),
              if (!isEnabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankAccountTile(BankAccount account) {
    final isSelected = _selectedBankAccount?.id == account.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedBankAccount = account;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A651).withOpacity(0.1) : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  isSelected ? const Color(0xFF00A651) : Colors.grey[300],
              child: Icon(
                Icons.account_balance,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        account.bankName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (account.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (account.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    account.maskedAccountNumber,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF00A651)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBankAccountsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No Bank Accounts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a bank account to receive payouts',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/add-bank-account');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Bank Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdown() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final processingFee = _calculatedFees!['processing_fee']!;
    final netAmount = _calculatedFees!['net_amount']!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fee Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeeRow('Payout Amount', amount),
            if (processingFee > 0)
              _buildFeeRow('Processing Fee', -processingFee, isNegative: true),
            const Divider(),
            _buildFeeRow('You\'ll Receive', netAmount, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, double amount,
      {bool isNegative = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isBold ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            '${isNegative ? "-" : ""}R${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isNegative
                  ? Colors.red
                  : (isBold ? const Color(0xFF00A651) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  bool _isMethodEnabled(PayoutMethod method) {
    switch (method) {
      case PayoutMethod.bank_transfer:
      case PayoutMethod.instant_eft:
        return true;
      case PayoutMethod.digital_wallet:
      case PayoutMethod.crypto:
        return false; // Coming soon
    }
  }

  IconData _getMethodIcon(PayoutMethod method) {
    switch (method) {
      case PayoutMethod.bank_transfer:
        return Icons.account_balance;
      case PayoutMethod.instant_eft:
        return Icons.flash_on;
      case PayoutMethod.digital_wallet:
        return Icons.account_balance_wallet;
      case PayoutMethod.crypto:
        return Icons.currency_bitcoin;
    }
  }

  String _getMethodName(PayoutMethod method) {
    switch (method) {
      case PayoutMethod.bank_transfer:
        return 'Bank Transfer';
      case PayoutMethod.instant_eft:
        return 'Instant EFT';
      case PayoutMethod.digital_wallet:
        return 'Digital Wallet';
      case PayoutMethod.crypto:
        return 'Cryptocurrency';
    }
  }

  String _getMethodDescription(PayoutMethod method) {
    switch (method) {
      case PayoutMethod.bank_transfer:
        return '1-3 business days • No fees';
      case PayoutMethod.instant_eft:
        return 'Within 2 hours • 2% fee';
      case PayoutMethod.digital_wallet:
        return 'Within 1 hour • 1% fee';
      case PayoutMethod.crypto:
        return '10-60 minutes • 0.5% fee';
    }
  }

  String _getProcessingInfo() {
    if (_isInstant) {
      return '• Instant payouts are processed within 30 minutes\n'
          '• Available 24/7 including weekends\n'
          '• Additional fees apply for instant processing\n'
          '• Funds will appear in your account immediately';
    } else {
      switch (_selectedMethod) {
        case PayoutMethod.bank_transfer:
          return '• Standard payouts are processed within 1-3 business days\n'
              '• No additional fees for standard processing\n'
              '• Processing occurs during business hours (9 AM - 5 PM)\n'
              '• You will receive a confirmation email';
        case PayoutMethod.instant_eft:
          return '• Instant EFT payouts are processed within 2 hours\n'
              '• Available during banking hours\n'
              '• 2% processing fee applies\n'
              '• Immediate confirmation provided';
        default:
          return '• Processing times vary by method\n'
              '• You will receive notifications about status updates\n'
              '• Contact support if you have any questions';
      }
    }
  }

  void _submitPayoutRequest() async {
    if (!_formKey.currentState!.validate() || _selectedBankAccount == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final result = await CompletePayoutService.requestPayout(
          taskerId: userId,
          amount: amount,
          bankAccount: _selectedBankAccount!,
          method: _selectedMethod,
          isInstant: _isInstant,
        );

        if (mounted) {
          if (result['success']) {
            Navigator.of(context).pop();
            widget.onPayoutRequested();
            _showSuccessDialog(result);
          } else {
            _showErrorDialog(result['error']);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payout Requested!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: R${result['net_amount'].toStringAsFixed(2)}'),
            if (result['processing_fee'] > 0)
              Text(
                  'Processing Fee: R${result['processing_fee'].toStringAsFixed(2)}'),
            Text('Estimated Arrival: ${result['estimated_arrival']}'),
            const SizedBox(height: 12),
            Text(
              result['message'],
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
            ),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

// Empty states and other supporting widgets
class EmptyEarningsState extends StatelessWidget {
  const EmptyEarningsState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No earnings history yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Complete tasks to start earning!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class EmptyPayoutsState extends StatelessWidget {
  const EmptyPayoutsState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No payouts yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Request your first payout when you have available earnings',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class EarningDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> earning;

  const EarningDetailsDialog({Key? key, required this.earning})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Earning Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Task', earning['task_title'] ?? 'Unknown'),
            _buildDetailRow('Category', earning['task_category'] ?? 'Unknown'),
            _buildDetailRow('Gross Amount',
                'R${earning['gross_amount'].toStringAsFixed(2)}'),
            _buildDetailRow('Platform Fee',
                'R${earning['platform_fee'].toStringAsFixed(2)}'),
            _buildDetailRow(
                'Net Earning', 'R${earning['net_earning'].toStringAsFixed(2)}'),
            _buildDetailRow(
                'Status', earning['escrow_status'].toString().toUpperCase()),
            _buildDetailRow('Date',
                DateFormat('MMM dd, yyyy HH:mm').format(earning['date'])),
            if (earning['released_at'] != null)
              _buildDetailRow(
                  'Released',
                  DateFormat('MMM dd, yyyy HH:mm')
                      .format(earning['released_at'])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: earning['is_available']
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    earning['is_available']
                        ? Icons.check_circle
                        : Icons.hourglass_empty,
                    color:
                        earning['is_available'] ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    earning['is_available']
                        ? 'Available for payout'
                        : 'Pending 24-hour release',
                    style: TextStyle(
                      color: earning['is_available']
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
            width: 100,
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
}

class PayoutDetailsDialog extends StatelessWidget {
  final PayoutModel payout;

  const PayoutDetailsDialog({Key? key, required this.payout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Payout #${payout.id.substring(0, 8)}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
                'Amount Requested', 'R${payout.amount.toStringAsFixed(2)}'),
            if (payout.processingFee > 0)
              _buildDetailRow('Processing Fee',
                  'R${payout.processingFee.toStringAsFixed(2)}'),
            _buildDetailRow(
                'Net Amount', 'R${payout.netAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Status', payout.status.name.toUpperCase()),
            _buildDetailRow('Method',
                payout.method.name.replaceAll('_', ' ').toUpperCase()),
            _buildDetailRow('Bank', payout.bankAccount.bankName),
            _buildDetailRow('Account', payout.bankAccount.maskedAccountNumber),
            _buildDetailRow('Requested',
                DateFormat('MMM dd, yyyy HH:mm').format(payout.createdAt)),
            if (payout.processedAt != null)
              _buildDetailRow('Processed',
                  DateFormat('MMM dd, yyyy HH:mm').format(payout.processedAt!)),
            if (payout.completedAt != null)
              _buildDetailRow('Completed',
                  DateFormat('MMM dd, yyyy HH:mm').format(payout.completedAt!)),
            if (payout.gatewayReference != null)
              _buildDetailRow('Reference', payout.gatewayReference!),
            if (payout.failureReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Failure Reason',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payout.failureReason!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (payout.status == PayoutStatus.failed)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Trigger retry logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
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
            width: 100,
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
}
