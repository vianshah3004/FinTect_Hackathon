import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../config/theme.dart';
import '../../services/game_service.dart';

class InterestMagicScreen extends StatefulWidget {
  const InterestMagicScreen({super.key});

  @override
  State<InterestMagicScreen> createState() => _InterestMagicScreenState();
}

class _InterestMagicScreenState extends State<InterestMagicScreen> {
  // Game Constants
  static const double interestRate = 0.08;
  static const int initialAmount = 100;
  static const int totalYears = 5;
  static const int rewardXP = 20;

  // Tree stages
  static const List<String> treeStages = ['🌱', '🌿', '🌳', '🌲', '🌲'];

  // State
  int currentYear = 0;
  int bankAmount = initialAmount;
  int homeAmount = initialAmount;
  int lenderAmount = initialAmount;

  bool isPlaying = false;
  bool isGameOver = false;
  bool isAnimating = false;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      isPlaying = true;
      currentYear = 0;
      bankAmount = initialAmount;
      homeAmount = initialAmount;
      lenderAmount = initialAmount;
      isGameOver = false;
    });
  }

  int _calculateGrowth(int principal, double rate, int years) {
    return (principal * pow(1 + rate, years)).round();
  }

  // Need pow from dart:math or helper
  double pow(double x, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= x;
    }
    return result;
  }

  void _nextYear() {
    if (isAnimating) return;

    setState(() {
      isAnimating = true;
    });

    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        currentYear++;

        // Update amounts
        bankAmount = _calculateGrowth(initialAmount, 0.08, currentYear);
        homeAmount = _calculateGrowth(initialAmount, 0.0, currentYear);
        lenderAmount = _calculateGrowth(
          initialAmount,
          -0.15,
          currentYear,
        ); // Loss

        // Cap lender loss at 0
        if (lenderAmount < 0) lenderAmount = 0;

        isAnimating = false;

        if (currentYear >= totalYears) {
          isGameOver = true;
          _confettiController.play();
          context.read<GameService>().awardMiniGameXP(rewardXP);
        }
      });
    });
  }

  void _resetGame() {
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isPlaying) return _buildIntroScreen();
    if (isGameOver) return _buildResultScreen();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Interest Magic'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Year $currentYear of $totalYears',
                  style: AppTypography.titleMedium,
                ),
                Container(
                  width: 200,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: currentYear / totalYears,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Tree Visual
            Container(
              height: 150,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    treeStages[min(currentYear, treeStages.length - 1)],
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 8),
                  Text('Your Money Tree', style: AppTypography.bodyMedium),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Comparison Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                childAspectRatio: 2.5,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.all(8),
                children: [
                  _buildComparisonCard(
                    'Bank Savings 🏦',
                    bankAmount,
                    bankAmount - initialAmount,
                    Colors.green.shade50,
                    Colors.green,
                    '+8% interest/year',
                  ),
                  _buildComparisonCard(
                    'Home Storage 🏠',
                    homeAmount,
                    0,
                    Colors.grey.shade50,
                    Colors.grey,
                    '0% growth',
                  ),
                  _buildComparisonCard(
                    'Moneylender 💸',
                    lenderAmount,
                    lenderAmount - initialAmount,
                    Colors.red.shade50,
                    Colors.red,
                    '-15% loss/year',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAnimating ? null : _nextYear,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  isAnimating
                      ? 'Growing...'
                      : 'Go to Year ${currentYear + 1} →',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Interest Magic')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              'Watch Your Money Grow!',
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'You have ₹100. Let\'s see what happens over 5 years with different choices.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 48),
            _buildInfoRow('🏦', 'Bank', '8% Interest'),
            const SizedBox(height: 16),
            _buildInfoRow('🏠', 'Home', '0% Growth'),
            const SizedBox(height: 16),
            _buildInfoRow('💸', 'Moneylender', '-15% Loss'),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                child: const Text('Plant Your Money Seed! 🌱'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 80)),
                  Text('Amazing!', style: AppTypography.headlineMedium),
                  const SizedBox(height: 16),
                  Text(
                    'You saw how money grows in a bank!',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      '+$rewardXP Points! 🪙',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💡 What You Learned:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Banks grow your money with compound interest',
                        ),
                        const Text('• Money at home doesn\'t grow'),
                        const Text(
                          '• Moneylenders can make you lose everything!',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back to Home'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _resetGame,
                        child: const Text('Play Again'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    String title,
    int amount,
    int change,
    Color bg,
    Color accent,
    String subtext,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '₹$amount',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subtext, style: TextStyle(color: accent, fontSize: 12)),
              if (currentYear > 0)
                Text(
                  change >= 0 ? '+₹$change' : '-₹${change.abs()}',
                  style: TextStyle(
                    color: change >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: amount / 200, // Normalized to double initial amount
              backgroundColor: Colors.white,
              color: accent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String title, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  int min(int a, int b) => a < b ? a : b;
}
