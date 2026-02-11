// lib/screens/payments/web_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/paystack_service.dart';
import '../../services/payment_service.dart';
import '../../models/transaction_model.dart';
import 'package:flutter/foundation.dart';
// Platform imports for WebView
import 'dart:io' show Platform;
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebPaymentScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  final String transactionId;
  final Function(bool success, Map<String, dynamic>? data) onPaymentComplete;

  const WebPaymentScreen({
    Key? key,
    required this.authorizationUrl,
    required this.reference,
    required this.transactionId,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<WebPaymentScreen> createState() => _WebPaymentScreenState();
}

class _WebPaymentScreenState extends State<WebPaymentScreen> {
  late final WebViewController _controller;
  bool isLoading = true;
  bool isVerifying = false;
  bool hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    print('🌐 Initializing WebView with URL: ${widget.authorizationUrl}');

    // Platform-specific WebView initialization
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('⏳ WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            print('📄 Page started loading: $url');
            _handleUrlChange(url);
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              isLoading = false;
            });
            _handleUrlChange(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            // Handle error gracefully
            if (mounted && !hasCompleted) {
              setState(() {
                isLoading = false;
              });
              _showErrorDialog(error.description ?? 'Unknown error occurred');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🧭 Navigation request: ${request.url}');
            _handleUrlChange(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));

    // Android-specific WebView setup
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  void _handleUrlChange(String url) {
    if (hasCompleted) return; // Prevent multiple completions

    print('🔍 Checking URL: $url');

    // Check for various completion indicators
    final completionIndicators = [
      'callback',
      'success',
      'cancel',
      'close',
      'trxref=${widget.reference}',
      'reference=${widget.reference}',
      widget.reference, // Direct reference match
    ];

    final hasCompletionIndicator = completionIndicators.any(
        (indicator) => url.toLowerCase().contains(indicator.toLowerCase()));

    if (hasCompletionIndicator) {
      print('🎯 Payment completion detected in URL');
      _verifyPayment();
    }
  }

  Future<void> _verifyPayment() async {
    if (isVerifying || hasCompleted) {
      print('⏸️ Already verifying or completed, skipping...');
      return;
    }

    print('🔍 Starting payment verification...');
    setState(() {
      isVerifying = true;
      hasCompleted = true;
    });

    try {
      // Wait a moment for payment to process
      await Future.delayed(const Duration(seconds: 2));

      final result = await PaystackService.verifyPayment(widget.reference);

      print('📊 Verification result: ${result['status']}');

      if (result['status'] == true) {
        print('✅ Payment successful, updating transaction...');

        // Payment successful - update transaction in Firebase
        final updateSuccess = await PaymentService.updateTransactionStatus(
          transactionId: widget.transactionId,
          status: TransactionStatus.authorized,
          escrowStatus: EscrowStatus.held,
          gatewayTransactionId: result['transaction_id'].toString(),
          gatewayReference: widget.reference,
        );

        print('📝 Transaction update: ${updateSuccess ? 'Success' : 'Failed'}');

        if (mounted) {
          Navigator.of(context).pop();
          widget.onPaymentComplete(true, result);
        }
      } else {
        print('❌ Payment failed, updating transaction...');

        // Payment failed - update transaction
        await PaymentService.updateTransactionStatus(
          transactionId: widget.transactionId,
          status: TransactionStatus.failed,
        );

        if (mounted) {
          Navigator.of(context).pop();
          widget.onPaymentComplete(false, result);
        }
      }
    } catch (e) {
      print('💥 Error during verification: $e');

      // Update transaction as failed
      await PaymentService.updateTransactionStatus(
        transactionId: widget.transactionId,
        status: TransactionStatus.failed,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onPaymentComplete(false, {'message': 'Verification error: $e'});
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close payment screen
              widget.onPaymentComplete(false, {'message': message});
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (!hasCompleted) {
              print('❌ Payment cancelled by user');
              setState(() {
                hasCompleted = true;
              });
              Navigator.of(context).pop();
              widget.onPaymentComplete(
                  false, {'message': 'Payment cancelled by user'});
            }
          },
        ),
        actions: [
          if (!isVerifying)
            TextButton(
              onPressed: () {
                if (!hasCompleted) {
                  print('🔄 Manual verification triggered');
                  _verifyPayment();
                }
              },
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          if (!kIsWeb) // Only show WebView on mobile platforms
            WebViewWidget(controller: _controller)
          else
            const Center(
              child: Text(
                'Payment processing is not supported on web platform.\nPlease use the mobile app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

          // Loading indicator
          if (isLoading && !kIsWeb)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00A651)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading payment page...',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while we redirect you to Paystack',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Verification overlay
          if (isVerifying)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Verifying payment...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while we confirm your payment',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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

  @override
  void dispose() {
    // Clean up controller when the widget is disposed
    // No need to dispose the controller as it's managed by the WebViewWidget
    super.dispose();
  }
}
