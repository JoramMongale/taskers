// lib/screens/dashboard/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_screen.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../tasks/create_task_screen_enhanced.dart';
import '../tasks/post_task_screen.dart';
import '../tasks/task_list_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../chat/conversations_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';
import '../../widgets/task_card.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? currentRole;
  User? currentUser;
  bool _isLoggingOut = false;
  List<Task> _myTasks = [];
  List<Task> _availableTasks = [];
  bool _isLoadingTasks = false;

  final List<Map<String, dynamic>> _navigationItems = [
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.task_alt, 'label': 'Tasks'},
    {'icon': Icons.message, 'label': 'Messages'},
    {'icon': Icons.person, 'label': 'Profile'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
    _loadTasks();

    // Initialize notification service
    NotificationService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    NotificationService.handleAppLifecycleChange(state);
  }

  Future<void> _initializeUser() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      currentRole = await AuthService.getCurrentRole();
      setState(() {});
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoadingTasks = true;
    });

    try {
      if (currentRole == 'poster' && currentUser != null) {
        _myTasks = await TaskService.getTasksByPoster(currentUser!.uid);
      } else if (currentRole == 'tasker') {
        _availableTasks = await TaskService.getAvailableTasks();
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }

    setState(() {
      _isLoadingTasks = false;
    });
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.task_alt,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _getPageTitle(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        // Role Switcher
        if (currentRole != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentRole,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                style: const TextStyle(
                  color: Color(0xFF00A651),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'poster',
                    child: Text('Poster'),
                  ),
                  DropdownMenuItem(
                    value: 'tasker',
                    child: Text('Tasker'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      currentRole = value;
                    });
                    AuthService.updateUserRole(value);
                    _loadTasks(); // Reload tasks for new role
                  }
                },
              ),
            ),
          ),

        // Profile Menu
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF00A651),
              child: currentUser?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        currentUser!.photoURL!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      ),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          onSelected: (value) {
            if (_isLoggingOut) {
              print('🛑 Logout already in progress, ignoring menu action');
              return;
            }

            print('📱 PopupMenu selected: $value');

            switch (value) {
              case 'profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
                break;
              case 'settings':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                break;
              case 'logout':
                _handleLogout();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 20),
                  const SizedBox(width: 12),
                  Text(currentUser?.displayName ?? 'Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      currentUser?.displayName?.substring(0, 1).toUpperCase() ??
          currentUser?.email?.substring(0, 1).toUpperCase() ??
          'U',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildTasksTab();
      case 2:
        return _buildMessagesTab();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A651), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    currentUser?.displayName ??
                        currentUser?.email?.split('@')[0] ??
                        'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentRole == 'poster'
                        ? 'What task do you need help with today?'
                        : 'Ready to help someone today?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            if (currentRole == 'poster') ...[
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.add_task,
                      title: 'Post Task',
                      color: const Color(0xFF00A651),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CreateTaskScreenEnhanced(),
                          ),
                        );
                        if (result == true) {
                          _loadTasks();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.search,
                      title: 'Browse Taskers',
                      color: Colors.blue,
                      onTap: () {
                        _showComingSoon('Browse Taskers');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Recent Tasks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentRole == 'poster'
                      ? 'My Recent Tasks'
                      : 'Available Tasks',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Color(0xFF00A651)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tasks List
            if (_isLoadingTasks)
              const Center(child: CircularProgressIndicator())
            else if (currentRole == 'poster')
              _buildPosterTasks()
            else
              _buildTaskerTasks(),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterTasks() {
    if (_myTasks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt,
        title: 'No tasks yet',
        subtitle: 'Post your first task to get started',
        actionLabel: 'Post Task',
        onAction: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTaskScreenEnhanced(),
            ),
          );
          if (result == true) {
            _loadTasks();
          }
        },
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myTasks.length > 3 ? 3 : _myTasks.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TaskCard(
            task: _myTasks[index],
            onTap: () => _openTaskDetail(_myTasks[index]),
          ),
        );
      },
    );
  }

  Widget _buildTaskerTasks() {
    if (_availableTasks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'No available tasks',
        subtitle: 'Check back later for new opportunities',
        actionLabel: 'Refresh',
        onAction: _loadTasks,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableTasks.length > 3 ? 3 : _availableTasks.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TaskCard(
            task: _availableTasks[index],
            onTap: () => _openTaskDetail(_availableTasks[index]),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab() {
    if (currentRole == 'poster') {
      return _buildPosterTasksView();
    } else {
      return const TaskListScreen();
    }
  }

  Widget _buildPosterTasksView() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Color(0xFF00A651),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF00A651),
              tabs: [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTasksList(TaskStatus.posted),
                _buildTasksList(TaskStatus.completed),
                _buildTasksList(TaskStatus.cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(TaskStatus status) {
    final filteredTasks =
        _myTasks.where((task) => task.status == status).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == TaskStatus.posted
                  ? Icons.task_alt
                  : status == TaskStatus.completed
                      ? Icons.check_circle
                      : Icons.cancel,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status.toString().split('.').last} tasks',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: filteredTasks[index],
              onTap: () => _openTaskDetail(filteredTasks[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesTab() {
    return const ConversationsScreen();
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF00A651),
      unselectedItemColor: Colors.grey,
      items: _navigationItems
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: item['label'],
            ),
          )
          .toList(),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_currentIndex == 0 && currentRole == 'poster') {
      return FloatingActionButton.extended(
        onPressed: () async {
          final userTypes = await AuthService.getUserTypes();
          if (userTypes == null || !userTypes.contains('poster')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please complete your profile to post tasks'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTaskScreenEnhanced(),
            ),
          );

          if (result == true) {
            _loadTasks();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Post a Task'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
      );
    }
    return null;
  }

  void _openTaskDetail(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
    _loadTasks(); // Reload in case task was updated
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

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Taskers';
      case 1:
        return 'My Tasks';
      case 2:
        return 'Messages';
      case 3:
        return 'Profile';
      default:
        return 'Taskers';
    }
  }
}
