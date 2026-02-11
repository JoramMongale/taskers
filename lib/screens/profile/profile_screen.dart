// lib/screens/profile/profile_screen.dart - Fixed version
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../widgets/taskrabbit_text_field.dart';
import '../settings/settings_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  XFile? _webImageFile; // For web
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  AppUser? _userData;

  // Tasker-specific fields
  final _hourlyRateController = TextEditingController();
  final _skillsController = TextEditingController();
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _zipCodeController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userData = await AuthService.getUserData(currentUser.uid);
      if (userData != null && mounted) {
        setState(() {
          _userData = userData;
          _firstNameController.text = userData.firstName;
          _lastNameController.text = userData.lastName;
          _phoneController.text = userData.phoneNumber;
          _addressController.text = userData.address;
          _zipCodeController.text = userData.zipCode;
          _profileImageUrl = userData.profileImageUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          if (kIsWeb) {
            _webImageFile = image;
          } else {
            _imageFile = File(image.path);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (!kIsWeb && _imageFile == null) return _profileImageUrl;
    if (kIsWeb && _webImageFile == null) return _profileImageUrl;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}.jpg');

      if (kIsWeb) {
        // Web upload
        final bytes = await _webImageFile!.readAsBytes();
        await ref.putData(bytes);
      } else {
        // Mobile upload
        await ref.putFile(_imageFile!);
      }

      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error uploading image: $e');
      _showSnackBar('Failed to upload image. Please try again.');
      return _profileImageUrl; // Return existing URL on error
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Upload image if new one selected
      String? imageUrl = _profileImageUrl;
      if ((_imageFile != null && !kIsWeb) ||
          (_webImageFile != null && kIsWeb)) {
        final uploadedUrl = await _uploadImage();
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'displayName':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'zipCode': _zipCodeController.text.trim(),
        'profileImageUrl': imageUrl ?? '',
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Update local storage
      await AuthService.saveUserDataLocally(
        uid: currentUser.uid,
        email: currentUser.email!,
        name:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        photoUrl: imageUrl ?? '',
        userTypes: _userData?.userTypes ?? [],
        currentRole: _userData?.currentRole ?? '',
      );

      _showSnackBar('Profile updated successfully!', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to update profile: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildProfileImage() {
    ImageProvider? imageProvider;

    if (!kIsWeb && _imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (kIsWeb && _webImageFile != null) {
      // For web, we'll show a loading indicator while uploading
      imageProvider = null;
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFF00A651),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? Text(
                  _userData?.displayName.isNotEmpty == true
                      ? _userData!.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.camera_alt,
                size: 20,
                color: Colors.white,
              ),
              onPressed: _pickImage,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'My Profile',
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
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: TextStyle(
                  color: _isSaving ? Colors.grey : const Color(0xFF00A651),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Profile Image
                        _buildProfileImage(),
                        const SizedBox(height: 16),
                        Text(
                          _userData?.email ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_userData?.createdAt != null)
                          Text(
                            'Member since ${DateFormat('MMMM yyyy').format(_userData!.createdAt!)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Basic Information
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // First Name
                          const Text(
                            'First Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TaskRabbitTextField(
                            controller: _firstNameController,
                            hintText: 'Enter your first name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Last Name
                          const Text(
                            'Last Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TaskRabbitTextField(
                            controller: _lastNameController,
                            hintText: 'Enter your last name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone Number
                          const Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TaskRabbitTextField(
                            controller: _phoneController,
                            hintText: '+27 XX XXX XXXX',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Address
                          const Text(
                            'Address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TaskRabbitTextField(
                            controller: _addressController,
                            hintText: 'Enter your address',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // Zip Code
                          const Text(
                            'Zip Code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TaskRabbitTextField(
                            controller: _zipCodeController,
                            hintText: 'Enter your zip code',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Account Settings (rest of the code remains the same)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email Verified Status
                        ListTile(
                          leading: Icon(
                            Icons.email,
                            color: _userData?.emailVerified == true
                                ? const Color(0xFF00A651)
                                : Colors.orange,
                          ),
                          title: const Text('Email Verification'),
                          subtitle: Text(
                            _userData?.emailVerified == true
                                ? 'Verified'
                                : 'Not verified',
                          ),
                          trailing: _userData?.emailVerified == true
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF00A651),
                                )
                              : TextButton(
                                  onPressed: _sendVerificationEmail,
                                  child: const Text('Verify'),
                                ),
                        ),

                        // Phone Verified Status
                        ListTile(
                          leading: Icon(
                            Icons.phone,
                            color: _userData?.phoneVerified == true
                                ? const Color(0xFF00A651)
                                : Colors.orange,
                          ),
                          title: const Text('Phone Verification'),
                          subtitle: Text(
                            _userData?.phoneVerified == true
                                ? 'Verified'
                                : 'Not verified',
                          ),
                          trailing: _userData?.phoneVerified == true
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF00A651),
                                )
                              : TextButton(
                                  onPressed: () =>
                                      _showComingSoon('Phone verification'),
                                  child: const Text('Verify'),
                                ),
                        ),

                        // User Roles
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Account Type'),
                          subtitle: Text(
                            _userData?.userTypes.join(', ') ?? 'Not set',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showRoleManagement(),
                        ),

                        // Notification Settings
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: const Text('Notification Settings'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showNotificationSettings(),
                        ),

                        // Privacy Settings
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Privacy & Security'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Privacy settings'),
                        ),

                        // Help & Support
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Help & Support'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Help & Support'),
                        ),

                        // Terms & Conditions
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Terms & Conditions'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showComingSoon('Terms & Conditions'),
                        ),

                        // Delete Account
                        ListTile(
                          leading: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          title: const Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.red),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.red),
                          onTap: () => _showDeleteAccountDialog(),
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

  void _showRoleManagement() {
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
                'Manage Account Types',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Poster'),
                subtitle: const Text('Post tasks and hire taskers'),
                value: _userData?.userTypes.contains('poster') ?? false,
                onChanged: (value) {
                  // Handle role change
                  _showComingSoon('Role management');
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: const Text('Tasker'),
                subtitle: const Text('Complete tasks and earn money'),
                value: _userData?.userTypes.contains('tasker') ?? false,
                onChanged: (value) {
                  // Handle role change
                  _showComingSoon('Role management');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and you will lose all your data.',
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
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Account deletion');
            },
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

  Future<void> _sendVerificationEmail() async {
    try {
      await AuthService.resendEmailVerification();
      _showSnackBar('Verification email sent!', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to send verification email: $e');
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
