// Replace your entire lib/screens/test/payment_test_screen.dart with this:
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskers/screens/payments/payment_launcher.dart';
import '../../models/transaction_model.dart';
import '../../widgets/payment_widgets.dart';
import '../../services/payment_service.dart';
import '../../services/paystack_service.dart';
import '../payments/web_payment_screen.dart';

class PaymentTestScreen extends StatefulWidget {
  const PaymentTestScreen({Key? key}) : super(key: key);

  @override
  State<PaymentTestScreen> createState() => _PaymentTestScreenState();
}

class _PaymentTestScreenState extends State<PaymentTestScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '1000');
  String selectedPaymentMethod = 'card';
  Map<String, double>? calculatedFees;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment System Test'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Payment Calculation Test',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Input
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Task Amount (ZAR)',
                        prefixText: 'R ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          calculatedFees = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Calculate Button
                    ElevatedButton(
                      onPressed: _calculateFees,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A651),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Calculate Fees'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            if (calculatedFees != null) ...[
              PaymentSummaryCard(
                taskAmount: calculatedFees!['task_amount']!,
                showBreakdown: true,
              ),

              // Detailed Breakdown Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Detailed Breakdown',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),

                      _buildDetailRow(
                          'Task Amount', calculatedFees!['task_amount']!),
                      _buildDetailRow(
                          'Service Fee (15%)', calculatedFees!['service_fee']!,
                          isDeduction: true),
                      _buildDetailRow(
                          'Trust Fee (7%)', calculatedFees!['trust_fee']!),
                      _buildDetailRow('Processing Fee (2.9%)',
                          calculatedFees!['processing_fee']!),

                      const Divider(height: 24),

                      _buildDetailRow(
                          'Poster Pays Total', calculatedFees!['total_amount']!,
                          isTotal: true),
                      _buildDetailRow(
                          'Tasker Receives', calculatedFees!['tasker_amount']!,
                          isEarning: true),

                      const SizedBox(height: 16),

                      // Money Flow Explanation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 Money Flow:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Poster pays R${calculatedFees!['total_amount']!.toStringAsFixed(2)} → '
                              'Tasker gets R${calculatedFees!['tasker_amount']!.toStringAsFixed(2)} + '
                              'Platform earns R${calculatedFees!['service_fee']!.toStringAsFixed(2)} + '
                              'Trust fund R${calculatedFees!['trust_fee']!.toStringAsFixed(2)} + '
                              'Gateway fee R${calculatedFees!['processing_fee']!.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Payment Method Test
            PaymentMethodSelector(
              selectedMethod: selectedPaymentMethod,
              onMethodChanged: (method) {
                setState(() {
                  selectedPaymentMethod = method;
                });
              },
            ),

            const SizedBox(height: 16),

            // Transaction Status Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏷️ Transaction Status Examples',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TransactionStatusBadge(
                          status: TransactionStatus.pending,
                          escrowStatus: EscrowStatus.none,
                        ),
                        TransactionStatusBadge(
                          status: TransactionStatus.authorized,
                          escrowStatus: EscrowStatus.held,
                        ),
                        TransactionStatusBadge(
                          status: TransactionStatus.captured,
                          escrowStatus: EscrowStatus.released,
                        ),
                        TransactionStatusBadge(
                          status: TransactionStatus.refunded,
                          escrowStatus: EscrowStatus.refunded,
                        ),
                        TransactionStatusBadge(
                          status: TransactionStatus.failed,
                          escrowStatus: EscrowStatus.none,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Paystack Test Cards Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💳 Paystack Test Cards',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildTestCardRow('Success',
                        PaystackService.testCards['success']!, Colors.green),
                    _buildTestCardRow(
                        'Insufficient Funds',
                        PaystackService.testCards['insufficient_funds']!,
                        Colors.red),
                    _buildTestCardRow(
                        'Invalid Card',
                        PaystackService.testCards['invalid_card']!,
                        Colors.orange),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Use CVV: 123, Expiry: Any future date, PIN: 1234',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Transaction Test Buttons
            if (calculatedFees != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🧪 Transaction Tests',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),

                      // Test Transaction Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _createTestTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Create Test Transaction (Firebase Only)'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Real Payment Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _testRealPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A651),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('🚀 Test Real Payment (Paystack)'),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Real payment will open Paystack payment page',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
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

  Widget _buildTestCardRow(String label, String cardNumber, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  cardNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isEarning = false,
    bool isDeduction = false,
  }) {
    Color? textColor;
    if (isTotal) textColor = const Color(0xFF00A651);
    if (isEarning) textColor = Colors.blue;
    if (isDeduction) textColor = Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight:
                  isTotal || isEarning ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          Text(
            'R${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight:
                  isTotal || isEarning ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _calculateFees() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      calculatedFees = TransactionModel.calculateFees(amount);
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calculated fees for R${amount.toStringAsFixed(2)}'),
        backgroundColor: const Color(0xFF00A651),
      ),
    );
  }

  Future<void> _createTestTransaction() async {
    if (calculatedFees == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate fees first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final transactionId = await PaymentService.createTransaction(
        taskId: 'test_task_${DateTime.now().millisecondsSinceEpoch}',
        posterId: 'test_poster_123',
        taskerId: 'test_tasker_456',
        taskAmount: calculatedFees!['task_amount']!,
        paymentMethod: selectedPaymentMethod,
      );

      if (transactionId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test transaction created: $transactionId'),
            backgroundColor: const Color(0xFF00A651),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        throw Exception('Failed to create transaction');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

// Update your _testRealPayment method in payment_test_screen.dart
// Replace the Navigator.push section with this:

  Future<void> _testRealPayment() async {
    if (calculatedFees == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate fees first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      print('🚀 Starting real payment test...');
      print('   User: ${currentUser.email}');
      print(
          '   Amount: R${calculatedFees!['total_amount']!.toStringAsFixed(2)}');

      // Create transaction first
      final transactionId = await PaymentService.createTransaction(
        taskId: 'test_task_${DateTime.now().millisecondsSinceEpoch}',
        posterId: currentUser.uid,
        taskerId: 'test_tasker_456',
        taskAmount: calculatedFees!['task_amount']!,
        paymentMethod: selectedPaymentMethod,
      );

      if (transactionId == null) {
        throw Exception('Failed to create transaction');
      }

      print('✅ Transaction created: $transactionId');

      // Initialize Paystack payment
      final paymentResult = await PaystackService.initializePayment(
        amount: calculatedFees!['total_amount']!,
        email: currentUser.email ?? 'test@taskers.co.za',
        taskId: 'test_task_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.uid,
        metadata: {
          'transaction_id': transactionId,
          'payment_method': selectedPaymentMethod,
          'user_name': currentUser.displayName ?? 'Test User',
        },
      );

      print('💳 Payment initialization result: ${paymentResult['status']}');

      if (paymentResult['status'] == true) {
        print('🌐 Launching payment...');

        // ✅ UPDATED: Use PaymentLauncher instead of direct WebView
        await PaymentLauncher.launchPayment(
          context: context,
          authorizationUrl: paymentResult['authorization_url'],
          reference: paymentResult['reference'],
          transactionId: transactionId,
          onPaymentComplete: (success, data) {
            print('🏁 Payment completed: $success');

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🎉 Payment successful!'),
                      const SizedBox(height: 4),
                      Text(
                        'Reference: ${paymentResult['reference']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (data?['channel'] != null)
                        Text(
                          'Method: ${data!['channel']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (data?['amount'] != null)
                        Text(
                          'Amount: R${data!['amount'].toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF00A651),
                  duration: const Duration(seconds: 8),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('❌ Payment failed'),
                      const SizedBox(height: 4),
                      Text(
                        data?['message'] ?? 'Unknown error',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 8),
                ),
              );
            }
          },
        );
      } else {
        throw Exception(
            paymentResult['message'] ?? 'Failed to initialize payment');
      }
    } catch (e) {
      print('💥 Payment test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
