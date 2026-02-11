import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  posted,
  assigned,
  inProgress,
  completed,
  cancelled,
}

enum BudgetType {
  fixed,
  hourly,
}

class Task {
  final String id;
  final String posterId;
  final String? taskerId;
  final String title;
  final String description;
  final String categoryId;
  final String subcategory;
  final BudgetType budgetType;
  final double budgetAmount;
  final DateTime? scheduledDate;
  final DateTime? scheduledTime;
  final TaskStatus status;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isUrgent;
  final String? notes;

  Task({
    required this.id,
    required this.posterId,
    this.taskerId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.subcategory,
    required this.budgetType,
    required this.budgetAmount,
    this.scheduledDate,
    this.scheduledTime,
    required this.status,
    required this.location,
    this.latitude,
    this.longitude,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isUrgent = false,
    this.notes,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      posterId: json['posterId'] ?? '',
      taskerId: json['taskerId'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? '',
      subcategory: json['subcategory'] ?? '',
      budgetType: BudgetType.values.firstWhere(
        (e) => e.toString() == 'BudgetType.${json['budgetType']}',
        orElse: () => BudgetType.fixed,
      ),
      budgetAmount: (json['budgetAmount'] ?? 0.0).toDouble(),
      scheduledDate: json['scheduledDate'] != null
          ? (json['scheduledDate'] as Timestamp).toDate()
          : null,
      scheduledTime: json['scheduledTime'] != null
          ? (json['scheduledTime'] as Timestamp).toDate()
          : null,
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == 'TaskStatus.${json['status']}',
        orElse: () => TaskStatus.posted,
      ),
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isUrgent: json['isUrgent'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'posterId': posterId,
      'taskerId': taskerId,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'subcategory': subcategory,
      'budgetType': budgetType.toString().split('.').last,
      'budgetAmount': budgetAmount,
      'scheduledDate':
          scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'scheduledTime':
          scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
      'status': status.toString().split('.').last,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isUrgent': isUrgent,
      'notes': notes,
    };
  }

  Task copyWith({
    String? id,
    String? posterId,
    String? taskerId,
    String? title,
    String? description,
    String? categoryId,
    String? subcategory,
    BudgetType? budgetType,
    double? budgetAmount,
    DateTime? scheduledDate,
    DateTime? scheduledTime,
    TaskStatus? status,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isUrgent,
    String? notes,
  }) {
    return Task(
      id: id ?? this.id,
      posterId: posterId ?? this.posterId,
      taskerId: taskerId ?? this.taskerId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      budgetType: budgetType ?? this.budgetType,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUrgent: isUrgent ?? this.isUrgent,
      notes: notes ?? this.notes,
    );
  }
}
