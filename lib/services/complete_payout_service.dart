import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payout_model.dart';
import '../models/transaction_model.dart';
import 'notification_service.dart';

class CompletePayoutService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // South African bank codes mapping
  static const Map<String, String> saBank_codes = {
    'ABSA Bank': '632005',
    'Standard Bank': '051001',
    'FNB': '250655',
    'Nedbank': '198765',
    'Capitec Bank': '470010',
    'Discovery Bank': '679000',
    'TymeBank': '678910',
    'African Bank': '430000',
    'Bidvest Bank': '462005',
    'Investec Bank': '580105',
  };

  // Request a comprehensive payout
  static Future<Map<String, dynamic>> requestPayout({
    required String taskerId,
    required double amount,
    required BankAccount bankAccount,
    PayoutMethod method = PayoutMethod.bank_transfer,
    bool isInstant = false,
  }) async {
    try {
      // Validate payout request
      final validation = await _validatePayoutRequest(taskerId, amount, bankAccount);
      if (!validation['valid']) {
        return {
          'success': false,
          'error': validation['error'],
        };
      }

      // Calculate fees
      final fees = _calculatePayoutFees(amount, method, isInstant);
      final netAmount = amount - fees['processing_fee']!;

      // Create payout record
      final payout = PayoutModel(
        id: '', // Will be set by Firestore
        taskerId: taskerId,
        amount: amount,
        processingFee: fees['processing_fee']!,
        netAmount: netAmount,
        bankAccount: bankAccount,
        status: PayoutStatus.pending,
        method: method,
        createdAt: DateTime.now(),
        metadata: {
          'is_instant': isInstant,
          'ip_address': 'user_ip_here',
          'device_info': 'user_device_here',
          'validation_checks': validation['checks'],
        },
      );

      // Save to database
      final payoutRef = await _firestore
          .collection('payouts')
          .add(payout.toMap());

      // Update tasker earnings
      await _updateTaskerEarningsForPayout(taskerId, amount);

      // Log payout request
      await _logPayoutAction(
        payoutId: payoutRef.id,
        taskerId: taskerId,
        action: 'payout_requested',
        amount: amount,
        metadata: {
          'method': method.name,
          'bank': bankAccount.bankName,
          'is_instant': isInstant,
        },
      );

      // Send notifications
      await _sendPayoutNotifications(taskerId, payout.copyWith(id: payoutRef.id));

      // Trigger processing (if instant or business hours)
      if (isInstant || _isBusinessHours()) {
        await _triggerPayoutProcessing(payoutRef.id);
      }

      return {
        'success': true,
        'payout_id': payoutRef.id,
        'net_amount': netAmount,
        'processing_fee': fees['processing_fee'],
        'estimated_arrival': _getEstimatedArrival(method, isInstant),
        'message': 'Payout request submitted successfully',
      };
    } catch (e) {
      print('Error requesting payout: $e');
      await _logPayoutAction(
        taskerId: taskerId,
        action: 'payout_request_failed',
        error: e.toString(),
      );
      return {
        'success': false,
        'error': 'System error: ${e.toString()}',
      };
    }
  }

  // Validate payout request thoroughly
  static Future<Map<String, dynamic>> _validatePayoutRequest(
    String taskerId,
    double amount,
    BankAccount bankAccount,
  ) async {
    final checks = <String, bool>{};
    
    try {
      // Check minimum amount
      checks['minimum_amount'] = amount >= 50.0;
      if (!checks['minimum_amount']!) {
        return {'valid': false, 'error': 'Minimum payout amount is R50.00'};
      }

      // Check maximum daily limit
      final dailyTotal = await _getDailyPayoutTotal(taskerId);
      checks['daily_limit'] = (dailyTotal + amount) <= 10000.0;
      if (!checks['daily_limit']!) {
        return {'valid': false, 'error': 'Daily payout limit exceeded (R10,000)'};
      }

      // Check available earnings
      final earnings = await getTaskerEarnings(taskerId);
      checks['sufficient_balance'] = amount <= earnings.availableEarnings;
      if (!checks['sufficient_balance']!) {
        return {'valid': false, 'error': 'Insufficient available earnings'};
      }

      // Check bank account verification
      checks['bank_verified'] = bankAccount.isVerified;
      if (!checks['bank_verified']!) {
        return {'valid': false, 'error': 'Bank account must be verified'};
      }

      // Check rate limiting
      checks['rate_limit'] = await _checkRateLimit(taskerId);
      if (!checks['rate_limit']!) {
        return {'valid': false, 'error': 'Too many payout requests. Try again later.'};
      }

      // Check account status
      checks['account_status'] = await _checkAccountStatus(taskerId);
      if (!checks['account_status']!) {
        return {'valid': false, 'error': 'Account restricted. Contact support.'};
      }

      return {
        'valid': true,
        'checks': checks,
      };
    } catch (e) {
      return {'valid': false, 'error': 'Validation error: ${e.toString()}'};
    }
  }

  // Calculate comprehensive payout fees
  static Map<String, double> _calculatePayoutFees(
    double amount,
    PayoutMethod method,
    bool isInstant,
  ) {
    double processingFee = 0.0;

    switch (method) {
      case PayoutMethod.bank_transfer:
        processingFee = isInstant ? amount * 0.015 : 0.0; // 1.5% for instant
        break;
      case PayoutMethod.instant_eft:
        processingFee = amount * 0.02; // 2% for instant EFT
        break;
      case PayoutMethod.digital_wallet:
        processingFee = amount * 0.01; // 1% for digital wallet
        break;
      case PayoutMethod.crypto:
        processingFee = amount * 0.005; // 0.5% for crypto
        break;
    }

    // Minimum fee
    if (processingFee > 0 && processingFee < 5.0) {
      processingFee = 5.0;
    }

    // Maximum fee cap
    if (processingFee > 100.0) {
      processingFee = 100.0;
    }

    return {
      'processing_fee': processingFee,
      'net_amount': amount - processingFee,
    };
  }

  // Get comprehensive tasker earnings
  static Future<TaskerEarnings> getTaskerEarnings(String taskerId) async {
    try {
      // Get earnings summary
      final earningsDoc = await _firestore
          .collection('tasker_earnings')
          .doc(taskerId)
          .get();

      if (!earningsDoc.exists) {
        // Initialize earnings for new tasker
        await _initializeTaskerEarnings(taskerId);
        return getTaskerEarnings(taskerId); // Recursive call after initialization
      }

      return TaskerEarnings.fromMap(earningsDoc.data()!, taskerId);
    } catch (e) {
      print('Error getting tasker earnings: $e');
      // Return empty earnings on error
      return TaskerEarnings(
        taskerId: taskerId,
        totalEarnings: 0.0,
        availableEarnings: 0.0,
        pendingEarnings: 0.0,
        pendingPayouts: 0.0,
        lifetimePayouts: 0.0,
        totalTasks: 0,
        completedTasks: 0,
        averageEarning: 0.0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  // Initialize earnings for new tasker
  static Future<void> _initializeTaskerEarnings(String taskerId) async {
    try {
      // Calculate historical earnings from transactions
      final transactions = await _firestore
          .collection('transactions')
          .where('tasker_id', isEqualTo: taskerId)
          .where('status', isEqualTo: TransactionStatus.captured.name)
          .get();

      double totalEarnings = 0.0;
      double availableEarnings = 0.0;
      int completedTasks = 0;

      for (final doc in transactions.docs) {
        final transaction = TransactionModel.fromMap(doc.data(), doc.id);
        totalEarnings += transaction.taskerAmount;
        completedTasks++;

        // Check if escrow is released
        if (transaction.escrowStatus == EscrowStatus.released &&
            transaction.releasedAt != null &&
            DateTime.now().difference(transaction.releasedAt!).inHours >= 24) {
          availableEarnings += transaction.taskerAmount;
        }
      }

      final avgEarning = completedTasks > 0 ? totalEarnings / completedTasks : 0.0;

      final earnings = TaskerEarnings(
        taskerId: taskerId,
        totalEarnings: totalEarnings,
        availableEarnings: availableEarnings,
        pendingEarnings: totalEarnings - availableEarnings,
        pendingPayouts: 0.0,
        lifetimePayouts: 0.0,
        totalTasks: completedTasks,
        completedTasks: completedTasks,
        averageEarning: avgEarning,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('tasker_earnings')
          .doc(taskerId)
          .set(earnings.toMap());
    } catch (e) {
      print('Error initializing tasker earnings: $e');
    }
  }

  // Update earnings when payout is requested
  static Future<void> _updateTaskerEarningsForPayout(
    String taskerId,
    double amount,
  ) async {
    try {
      await _firestore
          .collection('tasker_earnings')
          .doc(taskerId)
          .update({
        'available_earnings': FieldValue.increment(-amount),
        'pending_payouts': FieldValue.increment(amount),
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating earnings for payout: $e');
    }
  }

  // Comprehensive bank account management
  static Future<List<BankAccount>> getUserBankAccounts(String userId) async {
    try {
      final query = await _firestore
          .collection('user_bank_accounts')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return query.docs.map((doc) {
        return BankAccount.fromMap(doc.data());
      }).toList();
    } catch (e) {
      print('Error getting bank accounts: $e');
      return [];
    }
  }

  // Add new bank account with validation
  static Future<Map<String, dynamic>> addBankAccount({
    required String userId,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    required AccountType accountType,
    String? branchCode,
  }) async {
    try {
      // Validate bank details
      final validation = _validateBankDetails(
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolder: accountHolder,
        branchCode: branchCode,
      );

      if (!validation['valid']) {
        return {
          'success': false,
          'error': validation['error'],
        };
      }

      // Check for duplicates
      final existing = await _firestore
          .collection('user_bank_accounts')
          .where('user_id', isEqualTo: userId)
          .where('account_number', isEqualTo: accountNumber)
          .get();

      if (existing.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'This account is already registered',
        };
      }

      // Create bank account
      final bankAccount = BankAccount(
        id: _firestore.collection('user_bank_accounts').doc().id,
        bankName: bankName,
        bankCode: saBank_codes[bankName] ?? '',
        branchCode: branchCode ?? '',
        accountNumber: accountNumber,
        accountHolder: accountHolder,
        accountType: accountType,
        isVerified: false,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      // Save to database
      await _firestore
          .collection('user_bank_accounts')
          .doc(bankAccount.id)
          .set({
        'user_id': userId,
        ...bankAccount.toMap(),
      });

      // Trigger verification process
      await _triggerBankVerification(bankAccount.id);

      return {
        'success': true,
        'account_id': bankAccount.id,
        'message': 'Bank account added successfully. Verification in progress.',
      };
    } catch (e) {
      print('Error adding bank account: $e');
      return {
        'success': false,
        'error': 'Failed to add bank account: ${e.toString()}',
      };
    }
  }

  // Validate bank account details
  static Map<String, dynamic> _validateBankDetails({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    String? branchCode,
  }) {
    // Check bank name
    if (!saBank_codes.containsKey(bankName)) {
      return {'valid': false, 'error': 'Unsupported bank'};
    }

    // Validate account number format
    if (accountNumber.length < 8 || accountNumber.length > 11) {
      return {'valid': false, 'error': 'Invalid account number format'};
    }

    // Check account number is numeric
    if (!RegExp(r'^\d+$').hasMatch(accountNumber)) {
      return {'valid': false, 'error': 'Account number must contain only digits'};
    }

    // Validate account holder name
    if (accountHolder.trim().length < 2) {
      return {'valid': false, 'error': 'Invalid account holder name'};
    }

    // Check for prohibited characters
    if (!RegExp(r'^[a-zA-Z\s\-\'\.]+$').hasMatch(accountHolder)) {
      return {'valid': false, 'error': 'Account holder name contains invalid characters'};
    }

    return {'valid': true};
  }

  // Process payout (admin or automated)
  static Future<Map<String, dynamic>> processPayout(String payoutId) async {
    try {
      final payoutDoc = await _firestore
          .collection('payouts')
          .doc(payoutId)
          .get();

      if (!payoutDoc.exists) {
        return {'success': false, 'error': 'Payout not found'};
      }

      final payout = PayoutModel.fromMap(payoutDoc.data()!, payoutDoc.id);

      // Update status to processing
      await updatePayoutStatus(
        payoutId: payoutId,
        status: PayoutStatus.processing,
      );

      // Call banking API or payment gateway
      final result = await _processBankTransfer(payout);

      if (result['success']) {
        // Update to completed
        await updatePayoutStatus(
          payoutId: payoutId,
          status: PayoutStatus.completed,
          gatewayReference: result['reference'],
        );

        // Update lifetime payouts
        await _firestore
            .collection('tasker_earnings')
            .doc(payout.taskerId)
            .update({
          'lifetime_payouts': FieldValue.increment(payout.netAmount),
          'pending_payouts': FieldValue.increment(-payout.amount),
          'last_updated': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'message': 'Payout processed successfully',
          'reference': result['reference'],
        };
      } else {
        // Update to failed
        await updatePayoutStatus(
          payoutId: payoutId,
          status: PayoutStatus.failed,
          failureReason: result['error'],
        );

        // Return money to available earnings
        await _firestore
            .collection('tasker_earnings')
            .doc(payout.taskerId)
            .update({
          'available_earnings': FieldValue.increment(payout.amount),
          'pending_payouts': FieldValue.increment(-payout.amount),
          'last_updated': FieldValue.serverTimestamp(),
        });

        return {
          'success': false,
          'error': result['error'],
        };
      }
    } catch (e) {
      print('Error processing payout: $e');
      return {
        'success': false,
        'error': 'Processing error: ${e.toString()}',
      };
    }
  }

  // Helper methods
  static Future<double> _getDailyPayoutTotal(String taskerId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final query = await _firestore
        .collection('payouts')
        .where('tasker_id', isEqualTo: taskerId)
        .where('created_at', isGreaterThan: Timestamp.fromDate(startOfDay))
        .get();

    double total = 0.0;
    for (final doc in query.docs) {
      total += (doc.data()['amount'] ?? 0.0).toDouble();
    }
    return total;
  }

  static Future<bool> _checkRateLimit(String taskerId) async {
    final lastHour = DateTime.now().subtract(const Duration(hours: 1));
    
    final query = await _firestore
        .collection('payouts')
        .where('tasker_id', isEqualTo: taskerId)
        .where('created_at', isGreaterThan: Timestamp.fromDate(lastHour))
        .get();

    return query.docs.length < 3; // Max 3 payouts per hour
  }

  static Future<bool> _checkAccountStatus(String taskerId) async {
    final userDoc = await _firestore
        .collection('users')
        .doc(taskerId)
        .get();

    if (!userDoc.exists) return false;
    
    final userData = userDoc.data()!;
    return userData['account_status'] != 'restricted' &&
           userData['account_status'] != 'suspended';
  }

  static bool _isBusinessHours() {
    final now = DateTime.now();
    final hour = now.hour;
    final isWeekday = now.weekday >= 1 && now.weekday <= 5;
    return isWeekday && hour >= 9 && hour < 17; // 9 AM to 5 PM weekdays
  }

  static String _getEstimatedArrival(PayoutMethod method, bool isInstant) {
    if (isInstant) return 'Within 30 minutes';
    
    switch (method) {
      case PayoutMethod.bank_transfer:
        return '1-3 business days';
      case PayoutMethod.instant_eft:
        return 'Within 2 hours';
      case PayoutMethod.digital_wallet:
        return 'Within 1 hour';
      case PayoutMethod.crypto:
        return '10-60 minutes';
    }
  }

  // Mock banking API integration
  static Future<Map<String, dynamic>> _processBankTransfer(PayoutModel payout) async {
    try {
      // This would integrate with your actual banking API
      // For now, simulate processing
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Simulate 95% success rate
      if (DateTime.now().millisecond % 20 == 0) {
        return {
          'success': false,
          'error': 'Bank declined transaction - insufficient funds',
        };
      }
      
      return {
        'success': true,
        'reference': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'confirmation': 'CONF${payout.id.substring(0, 8)}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Banking API error: ${e.toString()}',
      };
    }
  }

  // Additional helper methods
  static Future<void> _triggerPayoutProcessing(String payoutId) async {
    try {
      await _functions
          .httpsCallable('processPayout')
          .call({'payoutId': payoutId});
    } catch (e) {
      print('Failed to trigger payout processing: $e');
    }
  }

  static Future<void> _triggerBankVerification(String accountId) async {
    try {
      await _functions
          .httpsCallable('verifyBankAccount')
          .call({'accountId': accountId});
    } catch (e) {
      print('Failed to trigger bank verification: $e');
    }
  }

  static Future<void> _sendPayoutNotifications(
    String taskerId,
    PayoutModel payout,
  ) async {
    try {
      // Notify tasker
      await NotificationService.sendNotification(
        userId: taskerId,
        title: 'Payout Request Received 💰',
        body: 'Your payout request for R${payout.netAmount.toStringAsFixed(2)} '
              'is being processed. ${_getEstimatedArrival(payout.method, false)}',
        data: {
          'type': 'payout_requested',
          'payout_id': payout.id,
          'amount': payout.netAmount.toString(),
          'method': payout.method.name,
        },
      );

      // Notify admins for large amounts
      if (payout.amount > 5000.0) {
        await NotificationService.sendAdminNotification(
          title: 'Large Payout Request',
          body: 'Payout of R${payout.amount.toStringAsFixed(2)} requested by tasker',
          data: {
            'type': 'large_payout',
            'payout_id': payout.id,
            'tasker_id': taskerId,
            'amount': payout.amount.toString(),
          },
        );
      }
    } catch (e) {
      print('Error sending payout notifications: $e');
    }
  }

  static Future<void> _logPayoutAction({
    String? payoutId,
    String? taskerId,
    required String action,
    double? amount,
    String? error,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore
          .collection('payout_logs')
          .add({
        'payout_id': payoutId,
        'tasker_id': taskerId,
        'action': action,
        'amount': amount,
        'error': error,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
        'ip_address': 'user_ip_here', // Would get from request
        'user_agent': 'user_agent_here', // Would get from request
      });
    } catch (e) {
      print('Error logging payout action: $e');
    }
  }

  // Update payout status with comprehensive tracking
  static Future<bool> updatePayoutStatus({
    required String payoutId,
    required PayoutStatus status,
    String? gatewayReference,
    String? failureReason,
    String? adminNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Add status-specific timestamps
      switch (status) {
        case PayoutStatus.processing:
          updateData['processed_at'] = FieldValue.serverTimestamp();
          break;
        case PayoutStatus.completed:
          updateData['completed_at'] = FieldValue.serverTimestamp();
          break;
        case PayoutStatus.failed:
        case PayoutStatus.cancelled:
          updateData['failed_at'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      if (gatewayReference != null) {
        updateData['gateway_reference'] = gatewayReference;
      }

      if (failureReason != null) {
        updateData['failure_reason'] = failureReason;
      }

      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      await _firestore
          .collection('payouts')
          .doc(payoutId)
          .update(updateData);

      // Log status change
      await _logPayoutAction(
        payoutId: payoutId,
        action: 'status_updated',
        metadata: {
          'new_status': status.name,
          'gateway_reference': gatewayReference,
          'failure_reason': failureReason,
          'admin_notes': adminNotes,
        },
      );

      // Send notifications based on status
      await _sendStatusNotification(payoutId, status);

      return true;
    } catch (e) {
      print('Error updating payout status: $e');
      return false;
    }
  }

  static Future<void> _sendStatusNotification(
    String payoutId,
    PayoutStatus status,
  ) async {
    try {
      final payoutDoc = await _firestore
          .collection('payouts')
          .doc(payoutId)
          .get();

      if (!payoutDoc.exists) return;

      final payout = PayoutModel.fromMap(payoutDoc.data()!, payoutDoc.id);
      String title, body;

      switch (status) {
        case PayoutStatus.processing:
          title = 'Payout Processing 🔄';
          body = 'Your payout of R${payout.netAmount.toStringAsFixed(2)} is being processed';
          break;
        case PayoutStatus.completed:
          title = 'Payout Completed! 🎉';
          body = 'R${payout.netAmount.toStringAsFixed(2)} has been sent to your bank account';
          break;
        case PayoutStatus.failed:
          title = 'Payout Failed ❌';
          body = 'Your payout failed. Funds returned to your balance.';
          break;
        case PayoutStatus.on_hold:
          title = 'Payout On Hold ⏸️';
          body = 'Your payout is temporarily on hold. We\'ll update you soon.';
          break;
        default:
          return;
      }

      await NotificationService.sendNotification(
        userId: payout.taskerId,
        title: title,
        body: body,
        data: {
          'type': 'payout_status_update',
          'payout_id': payoutId,
          'status': status.name,
          'amount': payout.netAmount.toString(),
        },
      );
    } catch (e) {
      print('Error sending status notification: $e');
    }
  }

  // Get tasker payout history with filters
  static Future<List<PayoutModel>> getTaskerPayouts({
    required String taskerId,
    PayoutStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('payouts')
          .where('tasker_id', isEqualTo: taskerId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (startDate != null) {
        query = query.where('created_at', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('created_at', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final result = await query
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) {
        return PayoutModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting tasker payouts: $e');
      return [];
    }
  }

  // Get payout analytics for tasker
  static Future<Map<String, dynamic>> getPayoutAnalytics(String taskerId) async {
    try {
      final payouts = await getTaskerPayouts(taskerId: taskerId);
      
      double totalPayouts = 0.0;
      double totalFees = 0.0;
      int successfulPayouts = 0;
      int failedPayouts = 0;
      
      Map<String, int> methodCounts = {};
      Map<String, double> monthlyPayouts = {};

      for (final payout in payouts) {
        if (payout.status == PayoutStatus.completed) {
          totalPayouts += payout.netAmount;
          totalFees += payout.processingFee;
          successfulPayouts++;
        } else if (payout.status == PayoutStatus.failed) {
          failedPayouts++;
        }

        // Method distribution
        methodCounts[payout.method.name] = 
            (methodCounts[payout.method.name] ?? 0) + 1;

        // Monthly distribution
        final monthKey = '${payout.createdAt.year}-${payout.createdAt.month.toString().padLeft(2, '0')}';
        if (payout.status == PayoutStatus.completed) {
          monthlyPayouts[monthKey] = 
              (monthlyPayouts[monthKey] ?? 0.0) + payout.netAmount;
        }
      }

      final successRate = (successfulPayouts + failedPayouts) > 0
          ? (successfulPayouts / (successfulPayouts + failedPayouts)) * 100
          : 0.0;

      return {
        'total_payouts': totalPayouts,
        'total_fees': totalFees,
        'successful_payouts': successfulPayouts,
        'failed_payouts': failedPayouts,
        'success_rate': successRate,
        'method_distribution': methodCounts,
        'monthly_payouts': monthlyPayouts,
        'average_payout': successfulPayouts > 0 ? totalPayouts / successfulPayouts : 0.0,
      };
    } catch (e) {
      print('Error getting payout analytics: $e');
      return {};
    }
  }

  // Admin functions
  static Future<Map<String, dynamic>> getAdminPayoutSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('payouts');

      if (startDate != null) {
        query = query.where('created_at', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('created_at', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final result = await query.get();
      
      double totalRequested = 0.0;
      double totalCompleted = 0.0;
      double totalFees = 0.0;
      
      Map<String, int> statusCounts = {};
      Map<String, int> methodCounts = {};

      for (final doc in result.docs) {
        final payout = PayoutModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
        
        totalRequested += payout.amount;
        
        if (payout.status == PayoutStatus.completed) {
          totalCompleted += payout.netAmount;
          totalFees += payout.processingFee;
        }

        statusCounts[payout.status.name] = 
            (statusCounts[payout.status.name] ?? 0) + 1;
        methodCounts[payout.method.name] = 
            (methodCounts[payout.method.name] ?? 0) + 1;
      }

      return {
        'total_requested': totalRequested,
        'total_completed': totalCompleted,
        'total_fees_collected': totalFees,
        'total_payouts': result.docs.length,
        'status_distribution': statusCounts,
        'method_distribution': methodCounts,
        'completion_rate': result.docs.isNotEmpty 
            ? ((statusCounts[PayoutStatus.completed.name] ?? 0) / result.docs.length) * 100 
            : 0.0,
      };
    } catch (e) {
      print('Error getting admin payout summary: $e');
      return {};
    }
  }

  // Get pending payouts for admin review
  static Future<List<PayoutModel>> getPendingPayouts({
    int limit = 50,
    bool largePriority = false,
  }) async {
    try {
      Query query = _firestore
          .collection('payouts')
          .where('status', isEqualTo: PayoutStatus.pending.name);

      if (largePriority) {
        query = query.where('amount', isGreaterThan: 5000.0);
      }

      final result = await query
          .orderBy('created_at', descending: false)
          .limit(limit)
          .get();

      return result.docs.map((doc) {
        return PayoutModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting pending payouts: $e');
      return [];
    }
  }

  // Bulk process payouts (admin function)
  static Future<Map<String, dynamic>> bulkProcessPayouts(
    List<String> payoutIds,
  ) async {
    try {
      int successful = 0;
      int failed = 0;
      List<String> errors = [];

      for (final payoutId in payoutIds) {
        final result = await processPayout(payoutId);
        if (result['success']) {
          successful++;
        } else {
          failed++;
          errors.add('${payoutId}: ${result['error']}');
        }
      }

      return {
        'successful': successful,
        'failed': failed,
        'errors': errors,
        'total_processed': payoutIds.length,
      };
    } catch (e) {
      return {
        'successful': 0,
        'failed': payoutIds.length,
        'errors': ['Bulk processing error: ${e.toString()}'],
        'total_processed': payoutIds.length,
      };
    }
  }

  // Set bank account as default
  static Future<bool> setDefaultBankAccount(
    String userId,
    String accountId,
  ) async {
    try {
      final batch = _firestore.batch();

      // Remove default from all accounts
      final allAccounts = await _firestore
          .collection('user_bank_accounts')
          .where('user_id', isEqualTo: userId)
          .get();

      for (final doc in allAccounts.docs) {
        batch.update(doc.reference, {'is_default': false});
      }

      // Set new default
      final accountRef = _firestore
          .collection('user_bank_accounts')
          .doc(accountId);
      batch.update(accountRef, {'is_default': true});

      await batch.commit();
      return true;
    } catch (e) {
      print('Error setting default bank account: $e');
      return false;
    }
  }

  // Remove bank account
  static Future<bool> removeBankAccount(
    String userId,
    String accountId,
  ) async {
    try {
      // Check if account has pending payouts
      final pendingPayouts = await _firestore
          .collection('payouts')
          .where('tasker_id', isEqualTo: userId)
          .where('status', whereIn: [
            PayoutStatus.pending.name,
            PayoutStatus.processing.name,
          ])
          .get();

      for (final doc in pendingPayouts.docs) {
        final payout = PayoutModel.fromMap(doc.data(), doc.id);
        if (payout.bankAccount.id == accountId) {
          return false; // Cannot remove account with pending payouts
        }
      }

      await _firestore
          .collection('user_bank_accounts')
          .doc(accountId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing bank account: $e');
      return false;
    }
  }

  // Verify bank account (would integrate with bank verification service)
  static Future<Map<String, dynamic>> verifyBankAccount(String accountId) async {
    try {
      // This would integrate with a bank verification service
      // For now, simulate verification
      
      await Future.delayed(const Duration(seconds: 3));
      
      // Simulate 90% success rate
      final isValid = DateTime.now().millisecond % 10 != 0;
      
      if (isValid) {
        await _firestore
            .collection('user_bank_accounts')
            .doc(accountId)
            .update({
          'is_verified': true,
          'verified_at': FieldValue.serverTimestamp(),
        });
        
        return {
          'success': true,
          'message': 'Bank account verified successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Bank account verification failed - invalid details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Verification error: ${e.toString()}',
      };
    }
  }

  // Get earnings history with detailed breakdown
  static Future<List<Map<String, dynamic>>> getDetailedEarningsHistory({
    required String taskerId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection('transactions')
          .where('tasker_id', isEqualTo: taskerId)
          .where('status', isEqualTo: TransactionStatus.captured.name);

      if (startDate != null) {
        query = query.where('created_at', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('created_at', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final result = await query
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> earnings = [];

      for (final doc in result.docs) {
        final transaction = TransactionModel.fromMap(doc.data(), doc.id);
        
        // Get task details
        final taskDoc = await _firestore
            .collection('tasks')
            .doc(transaction.taskId)
            .get();
        
        final taskData = taskDoc.exists ? taskDoc.data()! : {};

        earnings.add({
          'transaction_id': transaction.id,
          'task_id': transaction.taskId,
          'task_title': taskData['title'] ?? 'Unknown Task',
          'task_category': taskData['category'] ?? 'Unknown',
          'gross_amount': transaction.taskAmount,
          'platform_fee': transaction.serviceFee,
          'net_earning': transaction.taskerAmount,
          'escrow_status': transaction.escrowStatus.name,
          'date': transaction.createdAt,
          'released_at': transaction.releasedAt,
          'is_available': transaction.escrowStatus == EscrowStatus.released &&
              transaction.releasedAt != null &&
              DateTime.now().difference(transaction.releasedAt!).inHours >= 24,
        });
      }

      return earnings;
    } catch (e) {
      print('Error getting detailed earnings history: $e');
      return [];
    }
  }
}