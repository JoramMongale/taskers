import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class PaymentSummaryCard extends StatelessWidget {
  final double taskAmount;
  final bool showBreakdown;

  const PaymentSummaryCard({
    Key? key,
    required this.taskAmount,
    this.showBreakdown = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fees = TransactionModel.calculateFees(taskAmount);
    final formatter = NumberFormat.currency(symbol: 'R', decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildAmountRow(
              'Task Amount',
              formatter.format(fees['task_amount']),
              isMain: true,
            ),
            if (showBreakdown) ...[
              const Divider(height: 24),
              _buildAmountRow(
                'Trust & Support Fee',
                formatter.format(fees['trust_fee']),
                subtitle: 'Insurance & customer support',
              ),
              _buildAmountRow(
                'Processing Fee',
                formatter.format(fees['processing_fee']),
                subtitle: 'Secure payment processing',
              ),
              const Divider(height: 24),
            ],
            _buildAmountRow(
              'Total Amount',
              formatter.format(fees['total_amount']),
              isTotal: true,
            ),
            if (showBreakdown) ...[
              const SizedBox(height: 8),
              Text(
                'Tasker receives: ${formatter.format(fees['tasker_amount'])}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String amount, {
    String? subtitle,
    bool isMain = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isTotal ? 18 : 16,
                    fontWeight:
                        isTotal || isMain ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight:
                  isTotal || isMain ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF00A651) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;

  const PaymentMethodSelector({
    Key? key,
    required this.selectedMethod,
    required this.onMethodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption(
              'card',
              'Credit/Debit Card',
              'Visa, Mastercard accepted',
              Icons.credit_card,
            ),
            _buildPaymentOption(
              'eft',
              'Bank Transfer (EFT)',
              'Direct bank transfer',
              Icons.account_balance,
            ),
            _buildPaymentOption(
              'mobile',
              'Mobile Money',
              'MTN, Vodacom, Cell C',
              Icons.smartphone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = selectedMethod == value;

    return GestureDetector(
      onTap: () => onMethodChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
              icon,
              color: isSelected ? const Color(0xFF00A651) : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? const Color(0xFF00A651) : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00A651),
              ),
          ],
        ),
      ),
    );
  }
}

class TransactionStatusBadge extends StatelessWidget {
  final TransactionStatus status;
  final EscrowStatus escrowStatus;

  const TransactionStatusBadge({
    Key? key,
    required this.status,
    required this.escrowStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final info = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: info['color']),
      ),
      child: Text(
        info['text'],
        style: TextStyle(
          color: info['color'],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo() {
    switch (status) {
      case TransactionStatus.pending:
        return {'text': 'Pending', 'color': Colors.orange};
      case TransactionStatus.authorized:
        if (escrowStatus == EscrowStatus.held) {
          return {'text': 'Payment Held', 'color': Colors.blue};
        }
        return {'text': 'Authorized', 'color': Colors.blue};
      case TransactionStatus.captured:
        if (escrowStatus == EscrowStatus.released) {
          return {'text': 'Payment Released', 'color': Colors.green};
        }
        return {'text': 'Completed', 'color': Colors.green};
      case TransactionStatus.refunded:
        return {'text': 'Refunded', 'color': Colors.purple};
      case TransactionStatus.failed:
        return {'text': 'Failed', 'color': Colors.red};
      case TransactionStatus.cancelled:
        return {'text': 'Cancelled', 'color': Colors.grey};
    }
  }
}
