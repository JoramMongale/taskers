import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String taskId;
  final String posterId;
  final String taskerId;

  // Amount breakdown
  final double taskAmount; // Base task amount
  final double serviceFee; // 15% platform commission
  final double trustFee; // 7% trust & support fee
  final double processingFee; // 2.9% gateway fee
  final double totalAmount; // What poster pays
  final double taskerAmount; // What tasker receives

  // Payment details
  final String currency;
  final String paymentMethod;
  final String gateway;
  final String? gatewayTransactionId;
  final String? gatewayReference;

  // Status tracking
  final TransactionStatus status;
  final EscrowStatus escrowStatus;

  // Timestamps
  final DateTime createdAt;
  final DateTime? authorizedAt;
  final DateTime? capturedAt;
  final DateTime? releasedAt;

  TransactionModel({
    required this.id,
    required this.taskId,
    required this.posterId,
    required this.taskerId,
    required this.taskAmount,
    required this.serviceFee,
    required this.trustFee,
    required this.processingFee,
    required this.totalAmount,
    required this.taskerAmount,
    this.currency = 'ZAR',
    required this.paymentMethod,
    required this.gateway,
    this.gatewayTransactionId,
    this.gatewayReference,
    this.status = TransactionStatus.pending,
    this.escrowStatus = EscrowStatus.none,
    required this.createdAt,
    this.authorizedAt,
    this.capturedAt,
    this.releasedAt,
  });

  // Calculate fees for a task amount (CORRECTED)
  static Map<String, double> calculateFees(double taskAmount) {
    const serviceFeeRate = 0.15; // 15% - deducted from task amount
    const trustFeeRate = 0.07; // 7% - added to poster bill
    const processingFeeRate = 0.029; // 2.9% - added to poster bill

    final serviceFee = taskAmount * serviceFeeRate;
    final trustFee = taskAmount * trustFeeRate;
    final processingFee = taskAmount * processingFeeRate;

    // Tasker gets task amount minus service fee
    final taskerAmount = taskAmount - serviceFee;

    // Poster pays task amount + trust fee + processing fee
    final totalAmount = taskAmount + trustFee + processingFee;

    return {
      'task_amount': taskAmount,
      'service_fee': serviceFee,
      'trust_fee': trustFee,
      'processing_fee': processingFee,
      'total_amount': totalAmount,
      'tasker_amount': taskerAmount,
    };
  }

  // Create transaction with calculated fees
  static TransactionModel createWithFees({
    required String taskId,
    required String posterId,
    required String taskerId,
    required double taskAmount,
    required String paymentMethod,
    required String gateway,
  }) {
    final fees = calculateFees(taskAmount);

    return TransactionModel(
      id: '',
      taskId: taskId,
      posterId: posterId,
      taskerId: taskerId,
      taskAmount: fees['task_amount']!,
      serviceFee: fees['service_fee']!,
      trustFee: fees['trust_fee']!,
      processingFee: fees['processing_fee']!,
      totalAmount: fees['total_amount']!,
      taskerAmount: fees['tasker_amount']!,
      paymentMethod: paymentMethod,
      gateway: gateway,
      createdAt: DateTime.now(),
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'task_id': taskId,
      'poster_id': posterId,
      'tasker_id': taskerId,
      'task_amount': taskAmount,
      'service_fee': serviceFee,
      'trust_fee': trustFee,
      'processing_fee': processingFee,
      'total_amount': totalAmount,
      'tasker_amount': taskerAmount,
      'currency': currency,
      'payment_method': paymentMethod,
      'gateway': gateway,
      'gateway_transaction_id': gatewayTransactionId,
      'gateway_reference': gatewayReference,
      'status': status.name,
      'escrow_status': escrowStatus.name,
      'created_at': FieldValue.serverTimestamp(),
      'authorized_at': authorizedAt,
      'captured_at': capturedAt,
      'released_at': releasedAt,
    };
  }

  // Create from Firestore map
  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      taskId: map['task_id'] ?? '',
      posterId: map['poster_id'] ?? '',
      taskerId: map['tasker_id'] ?? '',
      taskAmount: (map['task_amount'] ?? 0.0).toDouble(),
      serviceFee: (map['service_fee'] ?? 0.0).toDouble(),
      trustFee: (map['trust_fee'] ?? 0.0).toDouble(),
      processingFee: (map['processing_fee'] ?? 0.0).toDouble(),
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      taskerAmount: (map['tasker_amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'ZAR',
      paymentMethod: map['payment_method'] ?? '',
      gateway: map['gateway'] ?? '',
      gatewayTransactionId: map['gateway_transaction_id'],
      gatewayReference: map['gateway_reference'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      escrowStatus: EscrowStatus.values.firstWhere(
        (e) => e.name == map['escrow_status'],
        orElse: () => EscrowStatus.none,
      ),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorizedAt: (map['authorized_at'] as Timestamp?)?.toDate(),
      capturedAt: (map['captured_at'] as Timestamp?)?.toDate(),
      releasedAt: (map['released_at'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with new values
  TransactionModel copyWith({
    String? id,
    TransactionStatus? status,
    EscrowStatus? escrowStatus,
    String? gatewayTransactionId,
    String? gatewayReference,
    DateTime? authorizedAt,
    DateTime? capturedAt,
    DateTime? releasedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      taskId: taskId,
      posterId: posterId,
      taskerId: taskerId,
      taskAmount: taskAmount,
      serviceFee: serviceFee,
      trustFee: trustFee,
      processingFee: processingFee,
      totalAmount: totalAmount,
      taskerAmount: taskerAmount,
      currency: currency,
      paymentMethod: paymentMethod,
      gateway: gateway,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      gatewayReference: gatewayReference ?? this.gatewayReference,
      status: status ?? this.status,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      createdAt: createdAt,
      authorizedAt: authorizedAt ?? this.authorizedAt,
      capturedAt: capturedAt ?? this.capturedAt,
      releasedAt: releasedAt ?? this.releasedAt,
    );
  }
}

enum TransactionStatus {
  pending,
  authorized,
  captured,
  refunded,
  failed,
  cancelled
}

enum EscrowStatus { none, held, released, disputed, refunded }
