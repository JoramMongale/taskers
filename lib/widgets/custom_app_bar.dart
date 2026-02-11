import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final User user;
  final String? currentRole;
  final Function(String) onRoleChanged;
  final VoidCallback onLogout;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.user,
    required this.currentRole,
    required this.onRoleChanged,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        // Role Switcher (if user has multiple roles)
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
                    onRoleChanged(value);
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
              child: user.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                // Navigate to profile screen
                break;
              case 'settings':
                // Navigate to settings screen
                break;
              case 'logout':
                onLogout();
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
                  Text(user.displayName ?? 'Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: const Row(
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
