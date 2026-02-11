// lib/screens/tasks/create_task_screen_enhanced.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/task_category.dart';
import '../../models/transaction_model.dart';
import '../../data/task_categories_data.dart';
import '../../widgets/taskrabbit_text_field.dart';
import '../../services/task_service.dart';
import '../../services/payment_service.dart';
import '../../services/paystack_service.dart';
import '../payments/web_payment_screen.dart';
import '../../services/notification_service.dart';

class CreateTaskScreenEnhanced extends StatefulWidget {
  const CreateTaskScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<CreateTaskScreenEnhanced> createState() =>
      _CreateTaskScreenEnhancedState();
}

class _CreateTaskScreenEnhancedState extends State<CreateTaskScreenEnhanced> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5; // Added payment step

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Form data
  TaskCategory? _selectedCategory;
  String? _selectedSubcategory;
  BudgetType _budgetType = BudgetType.fixed;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _isUrgent = false;
  bool _isLoading = false;
  Position? _currentPosition;

  // Payment related
  bool _requireUpfrontPayment = true;
  String _selectedPaymentMethod = 'card';
  Map<String, double>? _calculatedFees;
  String? _createdTaskId;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => _showExitDialog(),
        ),
        title: const Text(
          'Post a Task',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A651)),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Category(),
                _buildStep2Details(),
                _buildStep3Schedule(),
                _buildStep4Payment(), // New payment step
                _buildStep5Review(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStep1Category() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What do you need help with?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a category that best describes your task',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Popular Categories
          const Text(
            'Popular Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...TaskCategoriesData.getPopularCategories().map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCategoryTile(category),
            ),
          ),

          const SizedBox(height: 24),

          // All Categories
          const Text(
            'All Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...TaskCategoriesData.getCategories()
              .where((cat) => !cat.isPopular)
              .map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCategoryTile(category),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(TaskCategory category) {
    final isSelected = _selectedCategory?.id == category.id;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Color(0xFF00A651), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectCategory(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00A651)
                      : const Color(0xFF00A651).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category.iconName),
                  color: isSelected ? Colors.white : const Color(0xFF00A651),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF00A651)
                                : Colors.black87,
                          ),
                        ),
                        if (category.isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Popular',
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
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00A651),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about your task',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Subcategory Selection
          if (_selectedCategory != null) ...[
            const Text(
              'What specific service do you need?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubcategory,
                  hint: const Text('Select a service'),
                  isExpanded: true,
                  items: _selectedCategory!.subcategories.map((subcategory) {
                    return DropdownMenuItem<String>(
                      value: subcategory,
                      child: Text(subcategory),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Task Title
          const Text(
            'Task Title',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TaskRabbitTextField(
            controller: _titleController,
            hintText: 'e.g., Need help moving furniture',
            maxLines: 1,
          ),
          const SizedBox(height: 24),

          // Task Description
          const Text(
            'Task Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TaskRabbitTextField(
            controller: _descriptionController,
            hintText:
                'Describe what you need help with, any special requirements, etc.',
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          // Location
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TaskRabbitTextField(
                  controller: _locationController,
                  hintText: 'Enter your address or location',
                  suffixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                color: const Color(0xFF00A651),
                tooltip: 'Use current location',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Budget
          const Text(
            'Budget',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBudgetTypeButton(
                  'Fixed Price',
                  BudgetType.fixed,
                  Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBudgetTypeButton(
                  'Hourly Rate',
                  BudgetType.hourly,
                  Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'R',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TaskRabbitTextField(
                  controller: _budgetController,
                  hintText: _budgetType == BudgetType.fixed ? '500' : '25',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _calculateFees(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _budgetType == BudgetType.fixed ? 'total' : 'per hour',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          // Show fee breakdown if budget is entered
          if (_calculatedFees != null) ...[
            const SizedBox(height: 16),
            _buildFeeBreakdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeBreakdown() {
    if (_calculatedFees == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Fee Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeeRow('Task Amount', _calculatedFees!['task_amount']!),
          _buildFeeRow('Service Fee (15%)', _calculatedFees!['service_fee']!,
              isDeduction: true),
          _buildFeeRow('Tasker Receives', _calculatedFees!['tasker_amount']!,
              isBold: true),
          const Divider(height: 16),
          _buildFeeRow(
              'Trust & Support Fee (7%)', _calculatedFees!['trust_fee']!),
          _buildFeeRow(
              'Processing Fee (2.9%)', _calculatedFees!['processing_fee']!),
          const Divider(height: 16),
          _buildFeeRow('You\'ll Pay', _calculatedFees!['total_amount']!,
              isBold: true, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, double amount,
      {bool isDeduction = false, bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? Colors.blue[700] : Colors.black87,
            ),
          ),
          Text(
            '${isDeduction ? '-' : ''}R${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isDeduction
                  ? Colors.red
                  : isTotal
                      ? Colors.blue[700]
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTypeButton(String label, BudgetType type, IconData icon) {
    final isSelected = _budgetType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _budgetType = type;
          _calculateFees();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF00A651) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color(0xFF00A651).withOpacity(0.1)
              : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00A651) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF00A651) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Schedule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When do you need this done?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Urgent Toggle
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text(
                'This is urgent',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('I need this done ASAP'),
              value: _isUrgent,
              activeColor: const Color(0xFF00A651),
              onChanged: (value) {
                setState(() {
                  _isUrgent = value;
                });
              },
            ),
          ),

          if (!_isUrgent) ...[
            const SizedBox(height: 24),

            // Date Selection
            const Text(
              'Preferred Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF00A651)),
                    const SizedBox(width: 12),
                    Text(
                      _scheduledDate != null
                          ? DateFormat('EEEE, MMMM d, y')
                              .format(_scheduledDate!)
                          : 'Select a date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _scheduledDate != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Time Selection
            const Text(
              'Preferred Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF00A651)),
                    const SizedBox(width: 12),
                    Text(
                      _scheduledTime != null
                          ? _scheduledTime!.format(context)
                          : 'Select a time',
                      style: TextStyle(
                        fontSize: 16,
                        color: _scheduledTime != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Additional Notes
          const Text(
            'Additional Notes (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TaskRabbitTextField(
            controller: _notesController,
            hintText: 'Any special instructions or requirements...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Payment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment & Security',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Secure payment ensures quality work',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Trust & Safety Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF00A651).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: const Color(0xFF00A651),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your payment is secure',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Funds are held securely until task completion\n'
                  '• Automatic release 24 hours after completion\n'
                  '• Full refund if task is cancelled before start\n'
                  '• Dispute resolution support available',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment Method Selection
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          _buildPaymentMethodTile(
            'card',
            'Credit/Debit Card',
            'Visa, Mastercard, American Express',
            Icons.credit_card,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodTile(
            'bank',
            'Instant EFT',
            'All major South African banks',
            Icons.account_balance,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodTile(
            'wallet',
            'Digital Wallet',
            'Coming soon',
            Icons.account_balance_wallet,
            isDisabled: true,
          ),

          const SizedBox(height: 24),

          // Payment Timing
          const Text(
            'When to pay?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Payment is required when you accept a Tasker\'s application',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Show final fee breakdown
          if (_calculatedFees != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Total Cost Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFeeRow(
                        'Task Budget', _calculatedFees!['task_amount']!),
                    _buildFeeRow(
                        'Platform Fees',
                        _calculatedFees!['trust_fee']! +
                            _calculatedFees!['processing_fee']!),
                    const Divider(height: 16),
                    _buildFeeRow(
                        'Total Amount', _calculatedFees!['total_amount']!,
                        isBold: true, isTotal: true),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    String value,
    String title,
    String subtitle,
    IconData icon, {
    bool isDisabled = false,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDisabled
                ? Colors.grey[300]!
                : isSelected
                    ? const Color(0xFF00A651)
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDisabled
              ? Colors.grey[50]
              : isSelected
                  ? const Color(0xFF00A651).withOpacity(0.05)
                  : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDisabled
                  ? Colors.grey[400]
                  : isSelected
                      ? const Color(0xFF00A651)
                      : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00A651),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review your task',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure everything looks good before posting',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Review Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  _buildReviewItem(
                    'Category',
                    '${_selectedCategory?.name} - $_selectedSubcategory',
                    Icons.category,
                  ),
                  const Divider(height: 24),

                  // Title
                  _buildReviewItem(
                    'Title',
                    _titleController.text.isNotEmpty
                        ? _titleController.text
                        : 'Not specified',
                    Icons.title,
                  ),
                  const Divider(height: 24),

                  // Description
                  _buildReviewItem(
                    'Description',
                    _descriptionController.text.isNotEmpty
                        ? _descriptionController.text
                        : 'Not specified',
                    Icons.description,
                  ),
                  const Divider(height: 24),

                  // Location
                  _buildReviewItem(
                    'Location',
                    _locationController.text.isNotEmpty
                        ? _locationController.text
                        : 'Not specified',
                    Icons.location_on,
                  ),
                  const Divider(height: 24),

                  // Budget
                  _buildReviewItem(
                    'Budget',
                    _budgetController.text.isNotEmpty
                        ? 'R${_budgetController.text} ${_budgetType == BudgetType.fixed ? 'total' : 'per hour'}'
                        : 'Not specified',
                    Icons.attach_money,
                  ),
                  const Divider(height: 24),

                  // Schedule
                  _buildReviewItem(
                    'Schedule',
                    _isUrgent
                        ? 'Urgent - ASAP'
                        : _scheduledDate != null && _scheduledTime != null
                            ? '${DateFormat('EEEE, MMMM d').format(_scheduledDate!)} at ${_scheduledTime!.format(context)}'
                            : 'Flexible',
                    Icons.schedule,
                  ),

                  if (_notesController.text.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildReviewItem(
                      'Notes',
                      _notesController.text,
                      Icons.note,
                    ),
                  ],

                  const Divider(height: 24),

                  // Payment Summary
                  _buildReviewItem(
                    'Payment Method',
                    _selectedPaymentMethod == 'card'
                        ? 'Credit/Debit Card'
                        : 'Instant EFT',
                    Icons.payment,
                  ),

                  if (_calculatedFees != null) ...[
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A651).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Cost',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'R${_calculatedFees!['total_amount']!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A651),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Terms and Conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Before you post',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Your task will be visible to all Taskers\n'
                  '• Payment is only required when you accept a Tasker\n'
                  '• You can cancel anytime before accepting a Tasker\n'
                  '• Funds are held securely until task completion\n'
                  '• Both parties can rate and review each other',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF00A651),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                maxLines: title == 'Description' || title == 'Notes' ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF00A651)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Color(0xFF00A651),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == _totalSteps - 1
                          ? 'Post Task'
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectCategory(TaskCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedSubcategory = null; // Reset subcategory when changing category
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      _showSnackBar('Getting your location...', isInfo: true);

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Please enable location services');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationController.text =
            'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      });

      _showSnackBar('Location updated', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to get location: ${e.toString()}');
    }
  }

  void _calculateFees() {
    if (_budgetController.text.isEmpty) {
      setState(() {
        _calculatedFees = null;
      });
      return;
    }

    try {
      final amount = double.parse(_budgetController.text);
      setState(() {
        _calculatedFees = TransactionModel.calculateFees(amount);
      });
    } catch (e) {
      setState(() {
        _calculatedFees = null;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A651),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A651),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleNextStep() async {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // Post the task
      await _postTask();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Category
        if (_selectedCategory == null) {
          _showSnackBar('Please select a category');
          return false;
        }
        return true;
      case 1: // Details
        if (_selectedSubcategory == null) {
          _showSnackBar('Please select a specific service');
          return false;
        }
        if (_titleController.text.trim().isEmpty) {
          _showSnackBar('Please enter a task title');
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          _showSnackBar('Please enter a task description');
          return false;
        }
        if (_locationController.text.trim().isEmpty) {
          _showSnackBar('Please enter a location');
          return false;
        }
        if (_budgetController.text.trim().isEmpty) {
          _showSnackBar('Please enter a budget amount');
          return false;
        }
        try {
          double.parse(_budgetController.text.trim());
        } catch (e) {
          _showSnackBar('Please enter a valid budget amount');
          return false;
        }
        return true;
      case 2: // Schedule
        if (!_isUrgent && _scheduledDate == null) {
          _showSnackBar('Please select a preferred date or mark as urgent');
          return false;
        }
        return true;
      case 3: // Payment
        if (_selectedPaymentMethod.isEmpty) {
          _showSnackBar('Please select a payment method');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _postTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Combine scheduled date and time
      DateTime? scheduledDateTime;
      if (!_isUrgent && _scheduledDate != null) {
        scheduledDateTime = _scheduledDate!;
        if (_scheduledTime != null) {
          scheduledDateTime = DateTime(
            _scheduledDate!.year,
            _scheduledDate!.month,
            _scheduledDate!.day,
            _scheduledTime!.hour,
            _scheduledTime!.minute,
          );
        }
      }

      final task = Task(
        id: '', // Will be set by Firestore
        posterId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategory!.id,
        subcategory: _selectedSubcategory!,
        budgetType: _budgetType,
        budgetAmount: double.parse(_budgetController.text.trim()),
        scheduledDate: scheduledDateTime,
        scheduledTime: scheduledDateTime,
        status: TaskStatus.posted,
        location: _locationController.text.trim(),
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        imageUrls: [], // TODO: Implement image upload
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isUrgent: _isUrgent,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      _createdTaskId = await TaskService.createTask(task);

      // Send notification to nearby taskers (future implementation)
      // await NotificationService.notifyNearbyTaskers(task);

      _showSuccessDialog();
    } catch (e) {
      _showSnackBar('Failed to post task: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00A651),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Task Posted Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your task is now visible to Taskers. You\'ll be notified when someone applies.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen
            },
            child: const Text(
              'View My Tasks',
              style: TextStyle(
                color: Color(0xFF00A651),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    if (_currentStep > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Discard Task?'),
          content: const Text(
            'Are you sure you want to exit? Your task details will not be saved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continue Editing',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Exit screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isInfo = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? const Color(0xFF00A651)
            : isInfo
                ? Colors.blue
                : Colors.red,
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
