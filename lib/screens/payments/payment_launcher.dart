// Create: lib/screens/payments/payment_launcher.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/paystack_service.dart';
import '../../services/payment_service.dart';
import '../../models/transaction_model.dart';
import 'web_payment_screen.dart';

class PaymentLauncher {
  static Future<void> launchPayment({
    required BuildContext context,
    required String authorizationUrl,
    required String reference,
    required String transactionId,
    required Function(bool success, Map<String, dynamic>? data)
        onPaymentComplete,
  }) async {
    if (kIsWeb) {
      // For web: Launch in new tab and show verification dialog
      await _launchWebPayment(
        context: context,
        authorizationUrl: authorizationUrl,
        reference: reference,
        transactionId: transactionId,
        onPaymentComplete: onPaymentComplete,
      );
    } else {
      // For mobile: Use WebView
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebPaymentScreen(
              authorizationUrl: authorizationUrl,
              reference: reference,
              transactionId: transactionId,
              onPaymentComplete: onPaymentComplete,
            ),
          ),
        );
      } catch (e) {
        // If WebView fails on mobile, fallback to URL launcher
        print('📱 WebView failed on mobile, using URL launcher: $e');
        await _launchWebPayment(
          context: context,
          authorizationUrl: authorizationUrl,
          reference: reference,
          transactionId: transactionId,
          onPaymentComplete: onPaymentComplete,
        );
      }
    }
  }

  static Future<void> _launchWebPayment({
    required BuildContext context,
    required String authorizationUrl,
    required String reference,
    required String transactionId,
    required Function(bool success, Map<String, dynamic>? data)
        onPaymentComplete,
  }) async {
    try {
      print('🌐 Launching payment in external browser...');

      // Launch Paystack in new tab/browser
      final uri = Uri.parse(authorizationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        print('✅ Payment URL launched successfully');

        // Show verification dialog
        _showPaymentVerificationDialog(
          context: context,
          reference: reference,
          transactionId: transactionId,
          onPaymentComplete: onPaymentComplete,
        );
      } else {
        throw Exception('Could not launch payment URL');
      }
    } catch (e) {
      print('❌ Failed to launch payment: $e');
      onPaymentComplete(false, {'message': 'Failed to launch payment: $e'});
    }
  }

  static void _showPaymentVerificationDialog({
    required BuildContext context,
    required String reference,
    required String transactionId,
    required Function(bool success, Map<String, dynamic>? data)
        onPaymentComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PaymentVerificationDialog(
          reference: reference,
          transactionId: transactionId,
          onPaymentComplete: onPaymentComplete,
        );
      },
    );
  }
}

class PaymentVerificationDialog extends StatefulWidget {
  final String reference;
  final String transactionId;
  final Function(bool success, Map<String, dynamic>? data) onPaymentComplete;

  const PaymentVerificationDialog({
    Key? key,
    required this.reference,
    required this.transactionId,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentVerificationDialog> createState() =>
      _PaymentVerificationDialogState();
}

class _PaymentVerificationDialogState extends State<PaymentVerificationDialog> {
  bool isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment,
              color: Color(0xFF00A651),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Complete Payment',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Complete your payment in the browser tab that just opened\n'
                  '2. Use test card: 4084084084084081\n'
                  '3. CVV: 123, Expiry: 12/25, PIN: 1234\n'
                  '4. Come back here and click "Verify Payment"',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Reference: ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.reference,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isVerifying
              ? null
              : () {
                  Navigator.of(context).pop();
                  widget.onPaymentComplete(
                      false, {'message': 'Payment cancelled by user'});
                },
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: isVerifying ? null : _verifyPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A651),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Verify Payment'),
        ),
      ],
    );
  }

  Future<void> _verifyPayment() async {
    setState(() {
      isVerifying = true;
    });

    try {
      print('🔍 Verifying payment: ${widget.reference}');

      final result = await PaystackService.verifyPayment(widget.reference);

      print('📊 Verification result: ${result['status']}');

      if (result['status'] == true) {
        print('✅ Payment verified successfully');

        // Payment successful
        await PaymentService.updateTransactionStatus(
          transactionId: widget.transactionId,
          status: TransactionStatus.authorized,
          escrowStatus: EscrowStatus.held,
          gatewayTransactionId: result['transaction_id'].toString(),
          gatewayReference: widget.reference,
        );

        Navigator.of(context).pop();
        widget.onPaymentComplete(true, result);
      } else {
        print('❌ Payment verification failed');

        // Payment failed
        await PaymentService.updateTransactionStatus(
          transactionId: widget.transactionId,
          status: TransactionStatus.failed,
        );

        Navigator.of(context).pop();
        widget.onPaymentComplete(false, result);
      }
    } catch (e) {
      print('💥 Verification error: $e');

      Navigator.of(context).pop();
      widget.onPaymentComplete(false, {'message': 'Verification error: $e'});
    }
  }
}
