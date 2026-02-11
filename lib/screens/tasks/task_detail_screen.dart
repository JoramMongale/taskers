// File: lib/screens/tasks/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/task.dart';
import '../../data/task_categories_data.dart';
import '../../services/task_service.dart';
import '../chat/chat_screen.dart';
import '../../services/messaging_service.dart';
import '../../models/conversation.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = false;
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    final category = TaskCategoriesData.getCategoryById(_task.categoryId);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == _task.posterId;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isOwner && _task.status == TaskStatus.posted)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showComingSoon('Edit Task');
                    break;
                  case 'delete':
                    _showDeleteDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Edit Task'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete Task', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Content
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Category Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _task.subcategory,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00A651),
                              ),
                            ),
                            Text(
                              category?.name ?? 'Category',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(_task.status),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _task.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Time and Urgency
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Posted ${timeago.format(_task.createdAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_task.isUrgent) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
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

                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _task.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),

                  if (_task.notes != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Additional Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _task.notes!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Details Cards
            _buildDetailCard(
              'Budget',
              'R${_task.budgetAmount.toStringAsFixed(0)} ${_task.budgetType == BudgetType.fixed ? 'total' : 'per hour'}',
              Icons.attach_money,
              Colors.green,
            ),

            const SizedBox(height: 8),

            _buildDetailCard(
              'Location',
              _task.location,
              Icons.location_on,
              Colors.blue,
            ),

            if (_task.scheduledDate != null) ...[
              const SizedBox(height: 8),
              _buildDetailCard(
                'Scheduled',
                _formatScheduledDate(_task.scheduledDate!, _task.scheduledTime),
                Icons.calendar_today,
                Colors.orange,
              ),
            ],

            const SizedBox(height: 16),

            // Poster Information (for taskers)
            if (!isOwner) ...[
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Posted By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF00A651),
                          child: Text(
                            _task.posterId.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Task Poster',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Member since ${DateTime.now().year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _contactPoster,
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00A651),
                            side: const BorderSide(color: Color(0xFF00A651)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bottom padding for floating button
            const SizedBox(height: 80),
          ],
        ),
      ),

      // Action Button
      floatingActionButton: _buildActionButton(isOwner),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    Color color;
    String text;

    switch (status) {
      case TaskStatus.posted:
        color = const Color(0xFF00A651);
        text = 'Available';
        break;
      case TaskStatus.assigned:
        color = Colors.blue;
        text = 'Assigned';
        break;
      case TaskStatus.inProgress:
        color = Colors.orange;
        text = 'In Progress';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case TaskStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActionButton(bool isOwner) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    if (isOwner) {
      // Poster's view
      if (_task.status == TaskStatus.posted) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () => _showComingSoon('View Applications'),
            icon: const Icon(Icons.people),
            label: const Text('View Applications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
      return null;
    } else {
      // Tasker's view
      if (_task.status == TaskStatus.posted) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Contact Poster Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _contactPoster,
                  icon: const Icon(Icons.message),
                  label: const Text('Contact Poster'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00A651),
                    side: const BorderSide(color: Color(0xFF00A651)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Apply Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _applyForTask,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isLoading ? 'Applying...' : 'Apply for Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (_task.status == TaskStatus.assigned &&
          _task.taskerId == currentUser.uid) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Contact Poster Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _contactPoster,
                  icon: const Icon(Icons.message),
                  label: const Text('Message Poster'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00A651),
                    side: const BorderSide(color: Color(0xFF00A651)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Start Task Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showComingSoon('Start Task'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return null;
    }
  }

  Future<void> _contactPoster() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;

      // Check if conversation already exists
      final existingConversation = await MessagingService.getConversationByTask(
        _task.id,
        _task.posterId,
        currentUser.uid,
      );

      if (existingConversation != null) {
        // Open existing conversation
        _openChat(existingConversation);
      } else {
        // Start new conversation
        final conversationId = await MessagingService.startConversation(
          taskId: _task.id,
          posterId: _task.posterId,
          taskerId: currentUser.uid,
          initialMessage: "Hi! I'm interested in your task: ${_task.title}",
          taskData: {
            'title': _task.title,
            'budgetAmount': _task.budgetAmount,
            'location': _task.location,
          },
        );

        // Create conversation object and open chat
        final conversation = Conversation(
          id: conversationId,
          taskId: _task.id,
          posterId: _task.posterId,
          taskerId: currentUser.uid,
          lastMessage: "Hi! I'm interested in your task: ${_task.title}",
          lastMessageTime: DateTime.now(),
          lastMessageSenderId: currentUser.uid,
          unreadCount: 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          taskData: {
            'title': _task.title,
            'budgetAmount': _task.budgetAmount,
            'location': _task.location,
          },
        );

        _openChat(conversation);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start conversation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Add this method to open the chat screen:
  void _openChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
  }

  String _formatScheduledDate(DateTime date, DateTime? time) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    if (time != null) {
      final timeStr =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      return '$dateStr at $timeStr';
    }
    return dateStr;
  }

  Future<void> _applyForTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For now, just show a success message
      // In a real app, this would create an application record
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Color(0xFF00A651),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Task'),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteTask(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask() async {
    Navigator.pop(context); // Close dialog

    setState(() {
      _isLoading = true;
    });

    try {
      await TaskService.deleteTask(_task.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor: Color(0xFF00A651),
        ),
      );

      Navigator.pop(context, true); // Return to previous screen with result
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete task: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF00A651),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
