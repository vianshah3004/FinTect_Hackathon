import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/widgets.dart';

/// Lesson Detail Screen - Interactive learning content
class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  int _currentStep = 0;
  bool _lessonComplete = false;

  // Sample lesson steps
  final List<Map<String, dynamic>> _steps = [
    {
      'type': 'content',
      'emoji': '💰',
      'title': 'What is Savings?',
      'titleHi': 'बचत क्या है?',
      'content': 'Savings means keeping some money aside from what you earn for future use. It\'s like storing water for the dry season!',
      'contentHi': 'बचत का मतलब है अपनी कमाई का कुछ हिस्सा भविष्य के लिए अलग रखना। यह सूखे मौसम के लिए पानी जमा करने जैसा है!',
    },
    {
      'type': 'content',
      'emoji': '🏦',
      'title': 'Why Save Money?',
      'titleHi': 'पैसे क्यों बचाएं?',
      'content': '• For emergencies (medical, repairs)\n• For big purchases (phone, bike)\n• For children\'s education\n• For your own future\n• Peace of mind!',
      'contentHi': '• आपातकाल के लिए (इलाज, मरम्मत)\n• बड़ी खरीद के लिए (फोन, बाइक)\n• बच्चों की पढ़ाई के लिए\n• अपने भविष्य के लिए\n• मन की शांति!',
    },
    {
      'type': 'content',
      'emoji': '🎯',
      'title': 'The 10% Rule',
      'titleHi': '10% का नियम',
      'content': 'A simple rule: Save at least 10% of everything you earn!\n\nIf you earn ₹10,000:\n➡️ Save ₹1,000\n\nIf you earn ₹500 daily:\n➡️ Save ₹50 daily!',
      'contentHi': 'एक आसान नियम: जो भी कमाएं, उसका 10% जरूर बचाएं!\n\nअगर ₹10,000 कमाते हैं:\n➡️ ₹1,000 बचाएं\n\nअगर रोज ₹500 कमाते हैं:\n➡️ रोज ₹50 बचाएं!',
    },
    {
      'type': 'quiz',
      'question': 'If you earn ₹8,000 per month, how much should you save using the 10% rule?',
      'questionHi': 'अगर आप महीने में ₹8,000 कमाते हैं, तो 10% नियम के हिसाब से कितना बचाना चाहिए?',
      'options': ['₹500', '₹800', '₹1,000', '₹80'],
      'correctIndex': 1,
    },
    {
      'type': 'content',
      'emoji': '✅',
      'title': 'Lesson Complete!',
      'titleHi': 'पाठ पूरा हुआ!',
      'content': 'You\'ve learned the basics of savings!\n\n🎉 You earned 10 XP!\n\nRemember: Small daily savings lead to big amounts over time!',
      'contentHi': 'आपने बचत की मूल बातें सीख लीं!\n\n🎉 आपने 10 XP कमाए!\n\nयाद रखें: छोटी रोज़ाना बचत समय के साथ बड़ी रकम बन जाती है!',
    },
  ];

  int? _selectedOption;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isHindi = userProvider.language == 'hi';
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_steps.length, (index) {
            return Container(
              width: 24,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppColors.primaryAccent
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              isHindi ? 'बाद में' : 'Later',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: step['type'] == 'quiz'
                  ? _buildQuizStep(step, isHindi)
                  : _buildContentStep(step, isHindi),
            ),
          ),
          // Bottom navigation
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              top: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: _buildBottomButton(isHindi),
          ),
        ],
      ),
    );
  }

  Widget _buildContentStep(Map<String, dynamic> step, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            step['emoji'],
            style: const TextStyle(fontSize: 80),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          isHindi ? step['titleHi'] : step['title'],
          style: AppTypography.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            isHindi ? step['contentHi'] : step['content'],
            style: AppTypography.bodyLarge.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizStep(Map<String, dynamic> step, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text('🤔', style: TextStyle(fontSize: 80)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          isHindi ? 'प्रश्न' : 'Question',
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          isHindi ? step['questionHi'] : step['question'],
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        ...List.generate(step['options'].length, (index) {
          final isSelected = _selectedOption == index;
          final isCorrect = index == step['correctIndex'];
          
          Color? bgColor;
          Color? borderColor;
          
          if (_answered) {
            if (isCorrect) {
              bgColor = AppColors.success.withOpacity(0.15);
              borderColor = AppColors.success;
            } else if (isSelected && !isCorrect) {
              bgColor = AppColors.error.withOpacity(0.15);
              borderColor = AppColors.error;
            }
          } else if (isSelected) {
            bgColor = AppColors.primary.withOpacity(0.1);
            borderColor = AppColors.primary;
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: _answered ? null : () {
                setState(() {
                  _selectedOption = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor ?? Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected && !_answered
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected && !_answered
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step['options'][index],
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    if (_answered && isCorrect)
                      const Icon(Icons.check_circle, color: AppColors.success),
                    if (_answered && isSelected && !isCorrect)
                      const Icon(Icons.cancel, color: AppColors.error),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_answered)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedOption == step['correctIndex']
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  _selectedOption == step['correctIndex'] ? '🎉' : '💡',
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedOption == step['correctIndex']
                        ? (isHindi ? 'सही जवाब!' : 'Correct!')
                        : (isHindi 
                            ? 'सही जवाब है ₹800 (8,000 का 10%)' 
                            : 'Correct answer is ₹800 (10% of 8,000)'),
                    style: AppTypography.titleMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomButton(bool isHindi) {
    final step = _steps[_currentStep];
    
    if (step['type'] == 'quiz' && !_answered) {
      return PrimaryButton(
        text: isHindi ? 'जवाब चेक करें' : 'Check Answer',
        onPressed: _selectedOption == null ? () {} : () {
          setState(() {
            _answered = true;
          });
        },
      );
    }

    final isLastStep = _currentStep == _steps.length - 1;
    
    return PrimaryButton(
      text: isLastStep
          ? (isHindi ? 'पूरा करें 🎉' : 'Complete 🎉')
          : (isHindi ? 'आगे बढ़ें' : 'Continue'),
      onPressed: () {
        if (isLastStep) {
          // Complete lesson and go back
          context.pop();
        } else {
          setState(() {
            _currentStep++;
            _selectedOption = null;
            _answered = false;
          });
        }
      },
    );
  }
}
