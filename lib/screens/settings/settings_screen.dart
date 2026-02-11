import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppUser? _userData;
  bool _isLoading = true;

  // Notification Settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _taskUpdates = true;
  bool _messageAlerts = true;
  bool _promotionalEmails = false;

  // Privacy Settings
  bool _profileVisible = true;
  bool _showLocation = true;
  bool _showPhone = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userData = await AuthService.getUserData(currentUser.uid);
      if (userData != null && mounted) {
        setState(() {
          _userData = userData;
          _pushNotifications = userData.pushNotificationsEnabled;
          _emailNotifications = userData.emailNotificationsEnabled;
          _smsNotifications = userData.smsNotificationsEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationSetting(String field, bool value) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({field: value});

      _showSnackBar('Settings updated', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to update settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notifications Section
                  _buildSectionHeader('Notifications'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Push Notifications'),
                          subtitle: const Text(
                              'Receive notifications on your device'),
                          value: _pushNotifications,
                          onChanged: (value) {
                            setState(() {
                              _pushNotifications = value;
                            });
                            _updateNotificationSetting(
                                'pushNotificationsEnabled', value);
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Email Notifications'),
                          subtitle: const Text('Receive updates via email'),
                          value: _emailNotifications,
                          onChanged: (value) {
                            setState(() {
                              _emailNotifications = value;
                            });
                            _updateNotificationSetting(
                                'emailNotificationsEnabled', value);
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('SMS Notifications'),
                          subtitle:
                              const Text('Receive SMS for important updates'),
                          value: _smsNotifications,
                          onChanged: (value) {
                            setState(() {
                              _smsNotifications = value;
                            });
                            _updateNotificationSetting(
                                'smsNotificationsEnabled', value);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notification Types
                  _buildSectionHeader('Notification Types'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Task Updates'),
                          subtitle:
                              const Text('New applications, status changes'),
                          value: _taskUpdates,
                          onChanged: (_pushNotifications || _emailNotifications)
                              ? (value) {
                                  setState(() {
                                    _taskUpdates = value;
                                  });
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Message Alerts'),
                          subtitle: const Text('New messages from users'),
                          value: _messageAlerts,
                          onChanged: (_pushNotifications || _emailNotifications)
                              ? (value) {
                                  setState(() {
                                    _messageAlerts = value;
                                  });
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Promotional Emails'),
                          subtitle: const Text('Special offers and updates'),
                          value: _promotionalEmails,
                          onChanged: _emailNotifications
                              ? (value) {
                                  setState(() {
                                    _promotionalEmails = value;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Privacy Section
                  _buildSectionHeader('Privacy'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Profile Visibility'),
                          subtitle:
                              const Text('Allow others to view your profile'),
                          value: _profileVisible,
                          onChanged: (value) {
                            setState(() {
                              _profileVisible = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Show Location'),
                          subtitle:
                              const Text('Display your location to others'),
                          value: _showLocation,
                          onChanged: (value) {
                            setState(() {
                              _showLocation = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Show Phone Number'),
                          subtitle: const Text(
                              'Display your phone number on profile'),
                          value: _showPhone,
                          onChanged: (value) {
                            setState(() {
                              _showPhone = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account Section
                  _buildSectionHeader('Account'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showChangePasswordDialog(),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.payment),
                          title: const Text('Payment Methods'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Payment Methods'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: const Text('Transaction History'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Transaction History'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Support Section
                  _buildSectionHeader('Support'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Help Center'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Help Center'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.feedback_outlined),
                          title: const Text('Send Feedback'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Feedback'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.bug_report_outlined),
                          title: const Text('Report a Problem'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Report Problem'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Legal Section
                  _buildSectionHeader('Legal'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Terms of Service'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Terms of Service'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Privacy Policy'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.copyright_outlined),
                          title: const Text('Licenses'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Licenses'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Info
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Taskers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A651),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2024 Taskers South Africa',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Change Password'),
        content: const Text(
          'We\'ll send you an email with instructions to reset your password.',
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.sendPasswordResetEmail(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                );
                _showSnackBar('Password reset email sent!', isSuccess: true);
              } catch (e) {
                _showSnackBar('Failed to send reset email: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
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

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFF00A651) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
