import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/lesson.dart';
import '../../providers/user_provider.dart';

/// Learning Screen - Categories and lessons
class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isHindi = userProvider.language == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isHindi ? '📚 सीखें' : '📚 Learn'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Header
          Text(
            isHindi ? 'वित्तीय शिक्षा' : 'Financial Education',
            style: AppTypography.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isHindi 
                ? 'छोटे-छोटे lessons से पैसों को समझें!' 
                : 'Learn about money through bite-sized lessons!',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Categories
          ...LearningCategory.categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CategoryCard(
                title: isHindi ? category['titleHi'] : category['title'],
                description: isHindi 
                    ? category['descriptionHi'] 
                    : category['description'],
                icon: category['icon'],
                color: Color(category['color']),
                onTap: () {
                  // Navigate to category lessons
                  _showCategoryLessons(context, category, isHindi);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showCategoryLessons(
    BuildContext context, 
    Map<String, dynamic> category,
    bool isHindi,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(category['color']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          category['icon'],
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? category['titleHi'] : category['title'],
                            style: AppTypography.headlineSmall,
                          ),
                          Text(
                            isHindi 
                                ? category['descriptionHi'] 
                                : category['description'],
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Lessons list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: 5, // Sample lessons
                  itemBuilder: (context, index) {
                    return _LessonCard(
                      lessonNumber: index + 1,
                      title: isHindi 
                          ? 'पाठ ${index + 1}: ${_getSampleLessonTitle(category['id'], index, true)}'
                          : 'Lesson ${index + 1}: ${_getSampleLessonTitle(category['id'], index, false)}',
                      duration: '${3 + index} min',
                      xp: (index + 1) * 10,
                      isCompleted: index == 0,
                      onTap: () {
                        context.pop();
                        context.push('/lesson/${category['id']}_$index');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSampleLessonTitle(String categoryId, int index, bool isHindi) {
    final titles = {
      'savings': isHindi 
          ? ['बचत क्या है?', 'रोज़ बचत कैसे करें', 'बचत के फायदे', 'बचत खाता खोलें', 'बचत लक्ष्य बनाएं']
          : ['What is Savings?', 'Daily Savings Tips', 'Benefits of Saving', 'Open a Savings Account', 'Set Savings Goals'],
      'banking': isHindi
          ? ['बैंक क्या है?', 'खाता कैसे खोलें', 'ATM कैसे use करें', 'Mobile Banking', 'सुरक्षित Banking']
          : ['What is a Bank?', 'How to Open Account', 'Using ATM', 'Mobile Banking', 'Safe Banking'],
      'credit': isHindi
          ? ['लोन क्या है?', 'Interest को समझें', 'अच्छा vs बुरा कर्ज', 'लोन कैसे लें', 'EMI Calculator']
          : ['What is a Loan?', 'Understanding Interest', 'Good vs Bad Debt', 'How to Get Loans', 'EMI Calculator'],
    };
    
    return titles[categoryId]?[index] ?? (isHindi ? 'पाठ ${index + 1}' : 'Lesson ${index + 1}');
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final int lessonNumber;
  final String title;
  final String duration;
  final int xp;
  final bool isCompleted;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lessonNumber,
    required this.title,
    required this.duration,
    required this.xp,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isCompleted
              ? Border.all(color: AppColors.success, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white)
                    : Text(
                        '$lessonNumber',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(duration, style: AppTypography.bodySmall),
                      const SizedBox(width: 12),
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                      Text(' $xp XP', style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              color: AppColors.primary,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
