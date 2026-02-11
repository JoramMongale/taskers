import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/task_category.dart';
import '../../data/task_categories_data.dart';
import '../../services/task_service.dart';
import '../../widgets/taskrabbit_text_field.dart';
import 'task_detail_screen.dart';
import '../../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await TaskService.getAvailableTasks(
        categoryId: _selectedCategoryId,
      );

      setState(() {
        _tasks = tasks;
        _filteredTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tasks: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterTasks(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTasks = _tasks;
      });
      return;
    }

    final filtered = _tasks.where((task) {
      final searchableText =
          '${task.title} ${task.description} ${task.subcategory}'.toLowerCase();
      return searchableText.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredTasks = filtered;
    });
  }

  void _filterByCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Browse Tasks',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TaskRabbitTextField(
              controller: _searchController,
              hintText: 'Search tasks...',
              suffixIcon: const Icon(Icons.search),
              onChanged: _filterTasks,
            ),
          ),

          // Category Filter Chips
          if (_selectedCategoryId != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(
                      TaskCategoriesData.getCategoryById(_selectedCategoryId!)
                              ?.name ??
                          'Category',
                    ),
                    selected: true,
                    onSelected: (selected) {
                      if (!selected) {
                        _filterByCategory(null);
                      }
                    },
                    selectedColor: const Color(0xFF00A651).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF00A651),
                  ),
                ],
              ),
            ),

          // Task List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        color: const Color(0xFF00A651),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TaskCard(
                                task: _filteredTasks[index],
                                onTap: () =>
                                    _openTaskDetail(_filteredTasks[index]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategoryId != null
                ? 'Try adjusting your filters'
                : 'Be the first to post a task!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.clear),
                      title: const Text('All Categories'),
                      selected: _selectedCategoryId == null,
                      onTap: () {
                        _filterByCategory(null);
                        Navigator.pop(context);
                      },
                    ),
                    ...TaskCategoriesData.getCategories().map(
                      (category) => ListTile(
                        leading: Icon(_getCategoryIcon(category.iconName)),
                        title: Text(category.name),
                        selected: _selectedCategoryId == category.id,
                        onTap: () {
                          _filterByCategory(category.id);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTaskDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
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
