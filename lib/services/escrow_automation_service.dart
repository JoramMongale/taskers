import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/transaction_model.dart';
import '../models/task.dart';
import 'notification_service.dart';
import 'payment_service.dart';

class EscrowAutomationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static Timer? _automationTimer;

  // Start the escrow automation service
  static void startAutomationService() {
    // Run every 30 minutes to check for auto-releases
    _automationTimer = Timer.periodic(
      const Duration(minutes: 30),
      (timer) => _checkPendingReleases(),
    );
    print('Escrow automation service started');
  }

  // Stop the automation service
  static void stopAutomationService() {
    _automationTimer?.cancel();
    _automationTimer = null;
    print('Escrow automation service stopped');
  }

  // Main automation check function
  static Future<void> _checkPendingReleases() async {
    try {
      print('Checking for pending escrow releases...');

      // Get all completed tasks with held escrow
      final completedTasks = await _getCompletedTasksWithHeldEscrow();

      for (final task in completedTasks) {
        if (await _shouldAutoRelease(task)) {
          await _processAutoRelease(task);
        }
      }

      print('Escrow automation check completed');
    } catch (e) {
      print('Error in escrow automation: $e');
    }
  }

  // Get completed tasks with held escrow funds
  static Future<List<Task>> _getCompletedTasksWithHeldEscrow() async {
    try {
      final taskQuery = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: TaskStatus.completed.name)
          .where('payment_status', isEqualTo: 'authorized')
          .get();

      final tasks = <Task>[];
      for (final doc in taskQuery.docs) {
        // Check if transaction is in held escrow status
        final transactionQuery = await _firestore
            .collection('transactions')
            .where('task_id', isEqualTo: doc.id)
            .where('escrow_status', isEqualTo: EscrowStatus.held.name)
            .where('status', isEqualTo: TransactionStatus.captured.name)
            .get();

        if (transactionQuery.docs.isNotEmpty) {
          final task = Task.fromMap(doc.data(), doc.id);
          tasks.add(task);
        }
      }

      return tasks;
    } catch (e) {
      print('Error getting completed tasks: $e');
      return [];
    }
  }

  // Check if escrow should be auto-released (24 hours after completion)
  static Future<bool> _shouldAutoRelease(Task task) async {
    try {
      // Get completion timestamp
      if (task.completedAt == null) return false;

      // Check if 24 hours have passed
      final hoursSinceCompletion =
          DateTime.now().difference(task.completedAt!).inHours;

      // Auto-release after 24 hours, but check for any disputes first
      if (hoursSinceCompletion >= 24) {
        return await _checkNoActiveDisputes(task.id);
      }

      return false;
    } catch (e) {
      print('Error checking auto-release criteria: $e');
      return false;
    }
  }

  // Check if there are any active disputes for the task
  static Future<bool> _checkNoActiveDisputes(String taskId) async {
    try {
      final disputeQuery = await _firestore
          .collection('disputes')
          .where('task_id', isEqualTo: taskId)
          .where('status', whereIn: ['open', 'investigating']).get();

      return disputeQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking disputes: $e');
      return false; // Safe default - don't auto-release if uncertain
    }
  }

  // Process automatic escrow release
  static Future<void> _processAutoRelease(Task task) async {
    try {
      print('Auto-releasing escrow for task: ${task.id}');

      // Get the transaction
      final transactionQuery = await _firestore
          .collection('transactions')
          .where('task_id', isEqualTo: task.id)
          .where('escrow_status', isEqualTo: EscrowStatus.held.name)
          .get();

      if (transactionQuery.docs.isEmpty) {
        print('No held escrow found for task: ${task.id}');
        return;
      }

      final transactionDoc = transactionQuery.docs.first;
      final transaction = TransactionModel.fromMap(
        transactionDoc.data(),
        transactionDoc.id,
      );

      // Update escrow status to released
      await PaymentService.updateTransactionStatus(
        transaction.id,
        TransactionStatus.captured,
        escrowStatus: EscrowStatus.released,
      );

      // Update task payment status
      await _firestore.collection('tasks').doc(task.id).update({
        'payment_status': 'released',
        'escrow_released_at': FieldValue.serverTimestamp(),
      });

      // Add to tasker's available earnings
      await _updateTaskerEarnings(task.taskerId, transaction.taskerAmount);

      // Send notifications
      await _sendAutoReleaseNotifications(task, transaction);

      // Log the auto-release
      await _logEscrowAction(
        taskId: task.id,
        action: 'auto_release',
        amount: transaction.taskerAmount,
        reason: '24_hour_auto_release',
      );

      print('Escrow auto-released successfully for task: ${task.id}');
    } catch (e) {
      print('Error processing auto-release for task ${task.id}: $e');

      // Log the error for admin review
      await _logEscrowAction(
        taskId: task.id,
        action: 'auto_release_failed',
        reason: 'system_error',
        error: e.toString(),
      );
    }
  }

  // Update tasker's available earnings
  static Future<void> _updateTaskerEarnings(
    String taskerId,
    double amount,
  ) async {
    try {
      await _firestore.collection('tasker_earnings').doc(taskerId).set({
        'available_earnings': FieldValue.increment(amount),
        'total_earnings': FieldValue.increment(amount),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating tasker earnings: $e');
    }
  }

  // Send notifications for auto-release
  static Future<void> _sendAutoReleaseNotifications(
    Task task,
    TransactionModel transaction,
  ) async {
    try {
      // Notify tasker
      await NotificationService.sendNotification(
        userId: task.taskerId,
        title: 'Payment Released! 💰',
        body:
            'Your earnings of R${transaction.taskerAmount.toStringAsFixed(2)} '
            'for "${task.title}" are now available.',
        data: {
          'type': 'payment_released',
          'task_id': task.id,
          'amount': transaction.taskerAmount.toString(),
        },
      );

      // Notify poster
      await NotificationService.sendNotification(
        userId: task.posterId,
        title: 'Payment Completed ✅',
        body: 'Payment for "${task.title}" has been released to your Tasker.',
        data: {
          'type': 'payment_completed',
          'task_id': task.id,
        },
      );
    } catch (e) {
      print('Error sending auto-release notifications: $e');
    }
  }

  // Log escrow actions for audit trail
  static Future<void> _logEscrowAction({
    required String taskId,
    required String action,
    double? amount,
    String? reason,
    String? error,
  }) async {
    try {
      await _firestore.collection('escrow_logs').add({
        'task_id': taskId,
        'action': action,
        'amount': amount,
        'reason': reason,
        'error': error,
        'timestamp': FieldValue.serverTimestamp(),
        'automated': true,
      });
    } catch (e) {
      print('Error logging escrow action: $e');
    }
  }

  // Manual escrow release (for admin or immediate release)
  static Future<Map<String, dynamic>> manualEscrowRelease({
    required String taskId,
    required String adminId,
    String? reason,
  }) async {
    try {
      // Get task and transaction
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();

      if (!taskDoc.exists) {
        return {
          'success': false,
          'error': 'Task not found',
        };
      }

      final task = Task.fromMap(taskDoc.data()!, taskDoc.id);

      // Check if task is completed
      if (task.status != TaskStatus.completed) {
        return {
          'success': false,
          'error': 'Task must be completed before releasing escrow',
        };
      }

      // Get transaction
      final transactionQuery = await _firestore
          .collection('transactions')
          .where('task_id', isEqualTo: taskId)
          .where('escrow_status', isEqualTo: EscrowStatus.held.name)
          .get();

      if (transactionQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'No held escrow found for this task',
        };
      }

      final transactionDoc = transactionQuery.docs.first;
      final transaction = TransactionModel.fromMap(
        transactionDoc.data(),
        transactionDoc.id,
      );

      // Release escrow
      await PaymentService.updateTransactionStatus(
        transaction.id,
        TransactionStatus.captured,
        escrowStatus: EscrowStatus.released,
      );

      // Update task
      await _firestore.collection('tasks').doc(taskId).update({
        'payment_status': 'released',
        'escrow_released_at': FieldValue.serverTimestamp(),
        'released_by_admin': adminId,
      });

      // Update tasker earnings
      await _updateTaskerEarnings(task.taskerId, transaction.taskerAmount);

      // Send notifications
      await _sendAutoReleaseNotifications(task, transaction);

      // Log manual release
      await _logEscrowAction(
        taskId: taskId,
        action: 'manual_release',
        amount: transaction.taskerAmount,
        reason: reason ?? 'admin_manual_release',
      );

      return {
        'success': true,
        'message': 'Escrow released successfully',
        'amount': transaction.taskerAmount,
      };
    } catch (e) {
      print('Error in manual escrow release: $e');
      return {
        'success': false,
        'error': 'System error: ${e.toString()}',
      };
    }
  }

  // Get escrow summary for admin dashboard
  static Future<Map<String, dynamic>> getEscrowSummary() async {
    try {
      // Get held escrow transactions
      final heldQuery = await _firestore
          .collection('transactions')
          .where('escrow_status', isEqualTo: EscrowStatus.held.name)
          .get();

      double totalHeld = 0;
      int pendingReleases = 0;

      for (final doc in heldQuery.docs) {
        final transaction = TransactionModel.fromMap(doc.data(), doc.id);
        totalHeld += transaction.taskerAmount;

        // Check if ready for auto-release
        final taskDoc =
            await _firestore.collection('tasks').doc(transaction.taskId).get();

        if (taskDoc.exists) {
          final task = Task.fromMap(taskDoc.data()!, taskDoc.id);
          if (task.completedAt != null &&
              DateTime.now().difference(task.completedAt!).inHours >= 24) {
            pendingReleases++;
          }
        }
      }

      // Get recent releases (last 7 days)
      final recentReleasesQuery = await _firestore
          .collection('transactions')
          .where('escrow_status', isEqualTo: EscrowStatus.released.name)
          .where('released_at',
              isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
          .get();

      double recentReleased = 0;
      for (final doc in recentReleasesQuery.docs) {
        final transaction = TransactionModel.fromMap(doc.data(), doc.id);
        recentReleased += transaction.taskerAmount;
      }

      return {
        'total_held': totalHeld,
        'transactions_held': heldQuery.docs.length,
        'pending_auto_releases': pendingReleases,
        'recent_released_7days': recentReleased,
        'recent_releases_count': recentReleasesQuery.docs.length,
      };
    } catch (e) {
      print('Error getting escrow summary: $e');
      return {
        'total_held': 0.0,
        'transactions_held': 0,
        'pending_auto_releases': 0,
        'recent_released_7days': 0.0,
        'recent_releases_count': 0,
      };
    }
  }
}
