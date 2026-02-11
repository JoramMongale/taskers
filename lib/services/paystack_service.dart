// Create: lib/services/paystack_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class PaystackService {
  // 🔑 Replace these with your actual Paystack test keys
  static const String _testPublicKey =
      'pk_test_569052b32279f1d77bc5e33038ba462b22e89412';
  static const String _testSecretKey =
      'sk_test_8c068f8fdaeaf41e94c31c6e865578070ceee21d';

  static const String _baseUrl = 'https://api.paystack.co';

  // Initialize payment
  static Future<Map<String, dynamic>> initializePayment({
    required double amount,
    required String email,
    required String taskId,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final reference = _generateReference(taskId);

      print('🚀 Initializing Paystack payment:');
      print('   Amount: R${amount.toStringAsFixed(2)}');
      print('   Email: $email');
      print('   Reference: $reference');

      final response = await http.post(
        Uri.parse('$_baseUrl/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $_testSecretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Convert ZAR to cents
          'email': email,
          'reference': reference,
          'currency': 'ZAR',
          'callback_url': 'https://your-app.com/payment/callback',
          'metadata': {
            'task_id': taskId,
            'user_id': userId,
            'platform': 'taskers_sa',
            ...?metadata,
          },
          'channels': ['card', 'bank', 'ussd', 'qr'], // Payment methods
        }),
      );

      print('📡 Paystack initialize response: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          print('✅ Payment initialization successful');
          return {
            'status': true,
            'authorization_url': data['data']['authorization_url'],
            'access_code': data['data']['access_code'],
            'reference': reference,
            'message': 'Payment initialized successfully',
          };
        } else {
          print('❌ Payment initialization failed: ${data['message']}');
          return {
            'status': false,
            'message': data['message'] ?? 'Failed to initialize payment',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {
          'status': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Paystack initialize error: $e');
      return {
        'status': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Verify payment
  static Future<Map<String, dynamic>> verifyPayment(String reference) async {
    try {
      print('🔍 Verifying payment: $reference');

      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/verify/$reference'),
        headers: {
          'Authorization': 'Bearer $_testSecretKey',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Paystack verify response: ${response.statusCode}');
      print('📄 Verify response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final transactionData = data['data'];
          final isSuccess = transactionData['status'] == 'success';

          print(isSuccess
              ? '✅ Payment verified successfully'
              : '❌ Payment verification failed');

          return {
            'status': isSuccess,
            'amount': transactionData['amount'] / 100, // Convert back to ZAR
            'reference': transactionData['reference'],
            'gateway_response': transactionData['gateway_response'],
            'transaction_id': transactionData['id'],
            'paid_at': transactionData['paid_at'],
            'channel': transactionData['channel'],
            'currency': transactionData['currency'],
            'metadata': transactionData['metadata'],
            'customer': transactionData['customer'],
          };
        } else {
          print('❌ Verification API failed: ${data['message']}');
          return {
            'status': false,
            'message': data['message'] ?? 'Verification failed',
          };
        }
      } else {
        print('❌ Verification HTTP Error: ${response.statusCode}');
        return {
          'status': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Paystack verify error: $e');
      return {
        'status': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Create customer (for future saved payment methods)
  static Future<Map<String, dynamic>> createCustomer({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      print('👤 Creating Paystack customer: $email');

      final response = await http.post(
        Uri.parse('$_baseUrl/customer'),
        headers: {
          'Authorization': 'Bearer $_testSecretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          if (phone != null) 'phone': phone,
        }),
      );

      print('📡 Customer creation response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          print('✅ Customer created successfully');
          return {
            'status': true,
            'customer_id': data['data']['id'],
            'customer_code': data['data']['customer_code'],
          };
        }
      }

      print('❌ Customer creation failed');
      return {
        'status': false,
        'message': 'Failed to create customer',
      };
    } catch (e) {
      print('💥 Customer creation error: $e');
      return {
        'status': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Generate unique payment reference
  static String _generateReference(String taskId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final unique = '$taskId-$timestamp';
    final reference = 'TASK_${unique.substring(unique.length - 10)}';
    return reference;
  }

  // Get public key for frontend use
  static String get publicKey => _testPublicKey;

  // Validate Paystack webhook (for future use)
  static bool validateWebhook(String payload, String signature, String secret) {
    final hash = Hmac(sha512, utf8.encode(secret))
        .convert(utf8.encode(payload))
        .toString();
    return hash == signature;
  }

  // Get test card numbers for testing
  static Map<String, String> get testCards => {
        'success': '4084084084084081',
        'insufficient_funds': '4094940000000002',
        'invalid_card': '4094940000000036',
        'timeout': '4177700000000075',
      };
}
