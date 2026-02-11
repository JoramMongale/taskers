import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutModel {
  final String id;
  final String taskerId;
  final double amount;
  final double processingFee;
  final double netAmount;
  final BankAccount bankAccount;
  final PayoutStatus status;
  final PayoutMethod method;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final String? failureReason;
  final String? gatewayReference;
  final String? adminNotes;
  final Map<String, dynamic>? metadata;

  PayoutModel({
    required this.id,
    required this.taskerId,
    required this.amount,
    this.processingFee = 0.0,
    required this.netAmount,
    required this.bankAccount,
    required this.status,
    this.method = PayoutMethod.bank_transfer,
    required this.createdAt,
    this.processedAt,
    this.completedAt,
    this.failureReason,
    this.gatewayReference,
    this.adminNotes,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'tasker_id': taskerId,
      'amount': amount,
      'processing_fee': processingFee,
      'net_amount': netAmount,
      'bank_account': bankAccount.toMap(),
      'status': status.name,
      'method': method.name,
      'created_at': Timestamp.fromDate(createdAt),
      'processed_at':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completed_at':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failure_reason': failureReason,
      'gateway_reference': gatewayReference,
      'admin_notes': adminNotes,
      'metadata': metadata,
    };
  }

  factory PayoutModel.fromMap(Map<String, dynamic> map, String id) {
    return PayoutModel(
      id: id,
      taskerId: map['tasker_id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      processingFee: (map['processing_fee'] ?? 0.0).toDouble(),
      netAmount: (map['net_amount'] ?? 0.0).toDouble(),
      bankAccount: BankAccount.fromMap(map['bank_account'] ?? {}),
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PayoutStatus.pending,
      ),
      method: PayoutMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PayoutMethod.bank_transfer,
      ),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (map['processed_at'] as Timestamp?)?.toDate(),
      completedAt: (map['completed_at'] as Timestamp?)?.toDate(),
      failureReason: map['failure_reason'],
      gatewayReference: map['gateway_reference'],
      adminNotes: map['admin_notes'],
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  PayoutModel copyWith({
    PayoutStatus? status,
    DateTime? processedAt,
    DateTime? completedAt,
    String? failureReason,
    String? gatewayReference,
    String? adminNotes,
  }) {
    return PayoutModel(
      id: id,
      taskerId: taskerId,
      amount: amount,
      processingFee: processingFee,
      netAmount: netAmount,
      bankAccount: bankAccount,
      status: status ?? this.status,
      method: method,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      gatewayReference: gatewayReference ?? this.gatewayReference,
      adminNotes: adminNotes ?? this.adminNotes,
      metadata: metadata,
    );
  }
}

class BankAccount {
  final String id;
  final String bankName;
  final String bankCode;
  final String branchCode;
  final String accountNumber;
  final String accountHolder;
  final AccountType accountType;
  final bool isVerified;
  final bool isDefault;
  final DateTime createdAt;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.bankCode,
    required this.branchCode,
    required this.accountNumber,
    required this.accountHolder,
    required this.accountType,
    this.isVerified = false,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank_name': bankName,
      'bank_code': bankCode,
      'branch_code': branchCode,
      'account_number': accountNumber,
      'account_holder': accountHolder,
      'account_type': accountType.name,
      'is_verified': isVerified,
      'is_default': isDefault,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'] ?? '',
      bankName: map['bank_name'] ?? '',
      bankCode: map['bank_code'] ?? '',
      branchCode: map['branch_code'] ?? '',
      accountNumber: map['account_number'] ?? '',
      accountHolder: map['account_holder'] ?? '',
      accountType: AccountType.values.firstWhere(
        (e) => e.name == map['account_type'],
        orElse: () => AccountType.savings,
      ),
      isVerified: map['is_verified'] ?? false,
      isDefault: map['is_default'] ?? false,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }
}

class TaskerEarnings {
  final String taskerId;
  final double totalEarnings;
  final double availableEarnings;
  final double pendingEarnings;
  final double pendingPayouts;
  final double lifetimePayouts;
  final int totalTasks;
  final int completedTasks;
  final double averageEarning;
  final DateTime lastUpdated;

  TaskerEarnings({
    required this.taskerId,
    required this.totalEarnings,
    required this.availableEarnings,
    required this.pendingEarnings,
    required this.pendingPayouts,
    required this.lifetimePayouts,
    required this.totalTasks,
    required this.completedTasks,
    required this.averageEarning,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'tasker_id': taskerId,
      'total_earnings': totalEarnings,
      'available_earnings': availableEarnings,
      'pending_earnings': pendingEarnings,
      'pending_payouts': pendingPayouts,
      'lifetime_payouts': lifetimePayouts,
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'average_earning': averageEarning,
      'last_updated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory TaskerEarnings.fromMap(Map<String, dynamic> map, String taskerId) {
    return TaskerEarnings(
      taskerId: taskerId,
      totalEarnings: (map['total_earnings'] ?? 0.0).toDouble(),
      availableEarnings: (map['available_earnings'] ?? 0.0).toDouble(),
      pendingEarnings: (map['pending_earnings'] ?? 0.0).toDouble(),
      pendingPayouts: (map['pending_payouts'] ?? 0.0).toDouble(),
      lifetimePayouts: (map['lifetime_payouts'] ?? 0.0).toDouble(),
      totalTasks: map['total_tasks'] ?? 0,
      completedTasks: map['completed_tasks'] ?? 0,
      averageEarning: (map['average_earning'] ?? 0.0).toDouble(),
      lastUpdated:
          (map['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

enum PayoutStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  on_hold,
  returned
}

enum PayoutMethod { bank_transfer, instant_eft, digital_wallet, crypto }

enum AccountType { savings, current, transmission, bond }
