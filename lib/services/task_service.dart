import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tasksCollection = 'tasks';

  // Create a new task
  static Future<String> createTask(Task task) async {
    try {
      print('📝 Creating new task: ${task.title}');

      final docRef =
          await _firestore.collection(_tasksCollection).add(task.toJson());

      // Update the task with the generated ID
      await docRef.update({'id': docRef.id});

      print('✅ Task created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  // Get tasks by poster
  static Future<List<Task>> getTasksByPoster(String posterId) async {
    try {
      print('📖 Fetching tasks for poster: $posterId');

      final snapshot = await _firestore
          .collection(_tasksCollection)
          .where('posterId', isEqualTo: posterId)
          .orderBy('createdAt', descending: true)
          .get();

      final tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is set
        return Task.fromJson(data);
      }).toList();

      print('✅ Found ${tasks.length} tasks for poster');
      return tasks;
    } catch (e) {
      print('❌ Error fetching poster tasks: $e');
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  // Get available tasks for taskers (excluding own posts)
  static Future<List<Task>> getAvailableTasks({
    String? categoryId,
    double? maxDistance,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      print('🔍 Fetching available tasks...');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      Query query = _firestore
          .collection(_tasksCollection)
          .where('status', isEqualTo: 'posted')
          .where('posterId', isNotEqualTo: currentUser.uid) // Exclude own tasks
          .orderBy('posterId') // Required for inequality filter
          .orderBy('createdAt', descending: true);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await query.get();

      final tasks = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Task.fromJson(data);
      }).toList();

      print('✅ Found ${tasks.length} available tasks');
      return tasks;
    } catch (e) {
      print('❌ Error fetching available tasks: $e');
      throw Exception('Failed to fetch available tasks: $e');
    }
  }

  // Get a specific task by ID
  static Future<Task?> getTaskById(String taskId) async {
    try {
      print('📖 Fetching task: $taskId');

      final doc =
          await _firestore.collection(_tasksCollection).doc(taskId).get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id; // Ensure ID is set
        final task = Task.fromJson(data);
        print('✅ Task found: ${task.title}');
        return task;
      } else {
        print('❌ Task not found: $taskId');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching task: $e');
      throw Exception('Failed to fetch task: $e');
    }
  }

  // Update task status
  static Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      print('🔄 Updating task $taskId status to: $status');

      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task status updated successfully');
    } catch (e) {
      print('❌ Error updating task status: $e');
      throw Exception('Failed to update task status: $e');
    }
  }

  // Assign task to tasker
  static Future<void> assignTaskToTasker(String taskId, String taskerId) async {
    try {
      print('👤 Assigning task $taskId to tasker: $taskerId');

      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'taskerId': taskerId,
        'status': TaskStatus.assigned.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task assigned successfully');
    } catch (e) {
      print('❌ Error assigning task: $e');
      throw Exception('Failed to assign task: $e');
    }
  }

  // Delete task (only by poster, only if not assigned)
  static Future<void> deleteTask(String taskId) async {
    try {
      print('🗑️ Deleting task: $taskId');

      final task = await getTaskById(taskId);
      if (task == null) throw Exception('Task not found');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      if (task.posterId != currentUser.uid) {
        throw Exception('You can only delete your own tasks');
      }

      if (task.status != TaskStatus.posted) {
        throw Exception('Cannot delete task that has been assigned');
      }

      await _firestore.collection(_tasksCollection).doc(taskId).delete();

      print('✅ Task deleted successfully');
    } catch (e) {
      print('❌ Error deleting task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  // Search tasks
  static Future<List<Task>> searchTasks(String searchQuery) async {
    try {
      print('🔍 Searching tasks for: $searchQuery');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Firestore doesn't support full-text search, so we'll get all available tasks
      // and filter client-side (not ideal for large datasets, but OK for MVP)
      final allTasks = await getAvailableTasks();

      final searchTerms = searchQuery.toLowerCase().split(' ');

      final filteredTasks = allTasks.where((task) {
        final searchableText =
            '${task.title} ${task.description} ${task.subcategory}'
                .toLowerCase();
        return searchTerms.every((term) => searchableText.contains(term));
      }).toList();

      print('✅ Found ${filteredTasks.length} tasks matching search');
      return filteredTasks;
    } catch (e) {
      print('❌ Error searching tasks: $e');
      throw Exception('Failed to search tasks: $e');
    }
  }

  // Get tasks by status for current user
  static Future<List<Task>> getTasksByStatus(TaskStatus status,
      {bool asTasker = false}) async {
    try {
      print('📖 Fetching tasks with status: $status (asTasker: $asTasker)');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      Query query = _firestore
          .collection(_tasksCollection)
          .where('status', isEqualTo: status.toString().split('.').last);

      if (asTasker) {
        query = query.where('taskerId', isEqualTo: currentUser.uid);
      } else {
        query = query.where('posterId', isEqualTo: currentUser.uid);
      }

      query = query.orderBy('updatedAt', descending: true);

      final snapshot = await query.get();

      final tasks = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Task.fromJson(data);
      }).toList();

      print('✅ Found ${tasks.length} tasks with status $status');
      return tasks;
    } catch (e) {
      print('❌ Error fetching tasks by status: $e');
      throw Exception('Failed to fetch tasks by status: $e');
    }
  }

  // Get user's task statistics
  static Future<Map<String, int>> getUserTaskStats(String userId,
      {bool asTasker = false}) async {
    try {
      print('📊 Getting task stats for user: $userId (asTasker: $asTasker)');

      final userField = asTasker ? 'taskerId' : 'posterId';

      final snapshot = await _firestore
          .collection(_tasksCollection)
          .where(userField, isEqualTo: userId)
          .get();

      final tasks = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Task.fromJson(data);
      }).toList();

      final stats = <String, int>{
        'total': tasks.length,
        'posted': tasks.where((t) => t.status == TaskStatus.posted).length,
        'assigned': tasks.where((t) => t.status == TaskStatus.assigned).length,
        'inProgress':
            tasks.where((t) => t.status == TaskStatus.inProgress).length,
        'completed':
            tasks.where((t) => t.status == TaskStatus.completed).length,
        'cancelled':
            tasks.where((t) => t.status == TaskStatus.cancelled).length,
      };

      print('✅ Task stats retrieved: $stats');
      return stats;
    } catch (e) {
      print('❌ Error getting task stats: $e');
      throw Exception('Failed to get task stats: $e');
    }
  }
}
