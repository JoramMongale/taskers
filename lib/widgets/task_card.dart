// lib/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/task.dart';
import '../data/task_categories_data.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final category = TaskCategoriesData.getCategoryById(task.categoryId);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A651).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(category?.iconName ?? 'category'),
                      color: const Color(0xFF00A651),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.subcategory,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  _buildStatusBadge(task.status),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Info Row
              Row(
                children: [
                  // Budget
                  _buildInfoChip(
                    icon: Icons.attach_money,
                    label:
                        'R${task.budgetAmount.toStringAsFixed(0)}${task.budgetType == BudgetType.hourly ? '/hr' : ''}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),

                  // Location
                  if (task.location.isNotEmpty) ...[
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.location_on,
                        label: task.location,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Time
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: timeago.format(task.createdAt),
                    color: Colors.orange,
                  ),
                ],
              ),

              // Urgent Badge
              if (task.isUrgent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case TaskStatus.posted:
        color = const Color(0xFF00A651);
        text = 'Open';
        icon = Icons.circle_outlined;
        break;
      case TaskStatus.assigned:
        color = Colors.blue;
        text = 'Assigned';
        icon = Icons.person_outline;
        break;
      case TaskStatus.inProgress:
        color = Colors.orange;
        text = 'In Progress';
        icon = Icons.access_time;
        break;
      case TaskStatus.completed:
        color = Colors.green;
        text = 'Completed';
        icon = Icons.check_circle_outline;
        break;
      case TaskStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'build':
        return Icons.build;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'computer':
        return Icons.computer;
      case 'business':
        return Icons.business;
      case 'palette':
        return Icons.palette;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'directions_car':
        return Icons.directions_car;
      case 'school':
        return Icons.school;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.category;
    }
  }
}
