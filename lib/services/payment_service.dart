import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/transaction_model.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new transaction
  static Future<String?> createTransaction({
    required String taskId,
    required String posterId,
    required String taskerId,
    required double taskAmount,
    required String paymentMethod,
  }) async {
    try {
      final transaction = TransactionModel.createWithFees(
        taskId: taskId,
        posterId: posterId,
        taskerId: taskerId,
        taskAmount: taskAmount,
        paymentMethod: paymentMethod,
        gateway: 'paystack', // Default for now
      );

      final docRef =
          await _firestore.collection('transactions').add(transaction.toMap());

      return docRef.id;
    } catch (e) {
      print('Error creating transaction: $e');
      Fluttertoast.showToast(msg: 'Failed to create transaction');
      return null;
    }
  }

  // Get transaction by ID
  static Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      final doc =
          await _firestore.collection('transactions').doc(transactionId).get();

      if (doc.exists) {
        return TransactionModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  // Get transactions for a user
  static Future<List<TransactionModel>> getUserTransactions(
      String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('poster_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user transactions: $e');
      return [];
    }
  }

  // Get tasker earnings
  static Future<List<TransactionModel>> getTaskerEarnings(
      String taskerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('tasker_id', isEqualTo: taskerId)
          .where('status', isEqualTo: 'captured')
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting tasker earnings: $e');
      return [];
    }
  }

  // Update transaction status
  static Future<bool> updateTransactionStatus({
    required String transactionId,
    required TransactionStatus status,
    EscrowStatus? escrowStatus,
    String? gatewayTransactionId,
    String? gatewayReference,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (escrowStatus != null) {
        updateData['escrow_status'] = escrowStatus.name;
      }

      if (gatewayTransactionId != null) {
        updateData['gateway_transaction_id'] = gatewayTransactionId;
      }

      if (gatewayReference != null) {
        updateData['gateway_reference'] = gatewayReference;
      }

      // Add timestamps based on status
      switch (status) {
        case TransactionStatus.authorized:
          updateData['authorized_at'] = FieldValue.serverTimestamp();
          break;
        case TransactionStatus.captured:
          updateData['captured_at'] = FieldValue.serverTimestamp();
          if (escrowStatus == EscrowStatus.released) {
            updateData['released_at'] = FieldValue.serverTimestamp();
          }
          break;
        default:
          break;
      }

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error updating transaction status: $e');
      return false;
    }
  }

  // Calculate total earnings for a tasker
  static Future<Map<String, double>> calculateTaskerEarnings(
      String taskerId) async {
    try {
      final transactions = await getTaskerEarnings(taskerId);

      double totalEarnings = 0;
      double availableEarnings = 0;
      double pendingEarnings = 0;

      for (final transaction in transactions) {
        if (transaction.escrowStatus == EscrowStatus.released) {
          totalEarnings += transaction.taskerAmount;
          // Check if 24 hours have passed since release
          if (transaction.releasedAt != null &&
              DateTime.now().difference(transaction.releasedAt!).inHours >=
                  24) {
            availableEarnings += transaction.taskerAmount;
          } else {
            pendingEarnings += transaction.taskerAmount;
          }
        }
      }

      return {
        'total': totalEarnings,
        'available': availableEarnings,
        'pending': pendingEarnings,
      };
    } catch (e) {
      print('Error calculating tasker earnings: $e');
      return {'total': 0, 'available': 0, 'pending': 0};
    }
  }
}
