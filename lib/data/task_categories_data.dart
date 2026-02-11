// lib/data/task_categories_data.dart
import '../models/task_category.dart';

class TaskCategoriesData {
  static final List<TaskCategory> _categories = [
    TaskCategory(
      id: 'cleaning',
      name: 'Home Cleaning',
      description: 'House cleaning, deep cleaning, laundry services',
      iconName: 'home',
      subcategories: [
        'General House Cleaning',
        'Deep Cleaning',
        'Window Cleaning',
        'Carpet Cleaning',
        'Laundry & Ironing',
        'Post-Construction Cleaning',
        'Office Cleaning',
        'Move-in/Move-out Cleaning',
      ],
      isPopular: true,
    ),
    TaskCategory(
      id: 'handyman',
      name: 'Handyman Services',
      description: 'Repairs, installations, maintenance work',
      iconName: 'build',
      subcategories: [
        'General Repairs',
        'Furniture Assembly',
        'TV Mounting',
        'Plumbing',
        'Electrical Work',
        'Painting',
        'Carpentry',
        'Appliance Installation',
      ],
      isPopular: true,
    ),
    TaskCategory(
      id: 'moving',
      name: 'Moving & Delivery',
      description: 'Moving homes, furniture delivery, courier services',
      iconName: 'local_shipping',
      subcategories: [
        'Home Moving',
        'Office Moving',
        'Furniture Delivery',
        'Courier Services',
        'Heavy Lifting',
        'Packing Services',
        'Storage Solutions',
        'International Shipping',
      ],
      isPopular: true,
    ),
    TaskCategory(
      id: 'tech',
      name: 'Tech Support',
      description: 'Computer help, phone repair, smart home setup',
      iconName: 'computer',
      subcategories: [
        'Computer Repair',
        'Phone Repair',
        'WiFi Setup',
        'Smart Home Installation',
        'Data Recovery',
        'Virus Removal',
        'Software Installation',
        'Tech Tutoring',
      ],
      isPopular: false,
    ),
    TaskCategory(
      id: 'business',
      name: 'Business Services',
      description: 'Admin support, data entry, bookkeeping',
      iconName: 'business',
      subcategories: [
        'Data Entry',
        'Virtual Assistant',
        'Bookkeeping',
        'Document Preparation',
        'Translation',
        'Research',
        'Event Planning',
        'Marketing Support',
      ],
      isPopular: false,
    ),
    TaskCategory(
      id: 'creative',
      name: 'Creative Services',
      description: 'Photography, graphic design, content creation',
      iconName: 'palette',
      subcategories: [
        'Photography',
        'Videography',
        'Graphic Design',
        'Logo Design',
        'Content Writing',
        'Social Media Management',
        'Web Design',
        'Video Editing',
      ],
      isPopular: false,
    ),
    TaskCategory(
      id: 'personal',
      name: 'Personal Services',
      description: 'Shopping, errands, personal assistance',
      iconName: 'family_restroom',
      subcategories: [
        'Grocery Shopping',
        'Personal Shopping',
        'Errands',
        'Pet Care',
        'House Sitting',
        'Senior Care Assistance',
        'Childcare',
        'Personal Training',
      ],
      isPopular: true,
    ),
    TaskCategory(
      id: 'automotive',
      name: 'Automotive',
      description: 'Car wash, maintenance, driving services',
      iconName: 'directions_car',
      subcategories: [
        'Car Wash',
        'Car Detailing',
        'Oil Change',
        'Tire Change',
        'Jump Start',
        'Driving Services',
        'Car Inspection',
        'Minor Repairs',
      ],
      isPopular: false,
    ),
    TaskCategory(
      id: 'tutoring',
      name: 'Tutoring & Lessons',
      description: 'Academic tutoring, music lessons, language teaching',
      iconName: 'school',
      subcategories: [
        'Math Tutoring',
        'Science Tutoring',
        'Language Lessons',
        'Music Lessons',
        'Art Lessons',
        'Computer Skills',
        'Test Preparation',
        'Homework Help',
      ],
      isPopular: false,
    ),
    TaskCategory(
      id: 'events',
      name: 'Event Services',
      description: 'Party planning, catering help, event setup',
      iconName: 'celebration',
      subcategories: [
        'Event Setup',
        'Party Planning',
        'Catering Assistance',
        'DJ Services',
        'Decoration',
        'Photography',
        'Bartending',
        'Event Cleanup',
      ],
      isPopular: false,
    ),
  ];

  static List<TaskCategory> getCategories() {
    return _categories;
  }

  static List<TaskCategory> getPopularCategories() {
    return _categories.where((category) => category.isPopular).toList();
  }

  static TaskCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<String> getSubcategories(String categoryId) {
    final category = getCategoryById(categoryId);
    return category?.subcategories ?? [];
  }

  static String getCategoryName(String categoryId) {
    final category = getCategoryById(categoryId);
    return category?.name ?? 'Unknown Category';
  }

  static String getCategoryIcon(String categoryId) {
    final category = getCategoryById(categoryId);
    return category?.iconName ?? 'category';
  }
}
