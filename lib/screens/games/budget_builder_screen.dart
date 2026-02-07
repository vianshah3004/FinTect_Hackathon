import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../config/theme.dart';
import '../../services/game_service.dart';

class BudgetBuilderScreen extends StatefulWidget {
  const BudgetBuilderScreen({super.key});

  @override
  State<BudgetBuilderScreen> createState() => _BudgetBuilderScreenState();
}

class _BudgetBuilderScreenState extends State<BudgetBuilderScreen> {
  // Game Constants
  static const int monthlyIncome = 10000;
  static const int savingsGoal = 1000;
  static const int rewardXP = 30;

  // State
  List<String> selectedWants = [];
  GameEvent? currentEvent;
  bool isEventPhase = false;
  bool isResultPhase = false;
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

  int get totalNeeds => needs.fold(0, (sum, item) => sum + item.amount);

  int get totalWants => selectedWants.fold(0, (sum, id) {
    final item = wants.firstWhere(
      (w) => w.id == id,
      orElse: () => BudgetItem(id: '', name: '', emoji: '', amount: 0),
    );
    return sum + item.amount;
  });

  int get emergencyAmount => currentEvent?.amount ?? 0;
  int get totalSpent => totalNeeds + totalWants + emergencyAmount;
  int get remaining => monthlyIncome - totalSpent;

  void _toggleWant(String id) {
    setState(() {
      if (selectedWants.contains(id)) {
        selectedWants.remove(id);
      } else {
        selectedWants.add(id);
      }
    });
  }

  void _submitBudget() {
    setState(() {
      // Pick random event
      final random = Random();
      currentEvent = events[random.nextInt(events.length)];
      isEventPhase = true;
    });
  }

  void _showResults() {
    setState(() {
      isEventPhase = false;
      isResultPhase = true;
    });

    if (remaining >= savingsGoal) {
      _confettiController.play();
      context.read<GameService>().awardMiniGameXP(rewardXP);
    }
  }

  void _resetGame() {
    setState(() {
      selectedWants = [];
      currentEvent = null;
      isEventPhase = false;
      isResultPhase = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isResultPhase) return _buildResultScreen();
    if (isEventPhase) return _buildEventScreen();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget Builder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Income Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Income',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹$monthlyIncome',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Needs Section
                  const Text(
                    '📌 Fixed Needs (Must Pay)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...needs
                      .map(
                        (item) => Card(
                          color: Colors.grey.shade100,
                          child: ListTile(
                            leading: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(item.name),
                            trailing: Text(
                              '₹${item.amount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Total Needs: ₹$totalNeeds',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  // Wants Section
                  const Text(
                    '🎯 Optional Wants (Your Choice)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: wants.length,
                    itemBuilder: (context, index) {
                      final item = wants[index];
                      final isSelected = selectedWants.contains(item.id);
                      return GestureDetector(
                        onTap: () => _toggleWant(item.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${item.amount}',
                                style: const TextStyle(color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Selected Wants: ₹$totalWants',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total & Submit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining:'),
                    Text(
                      '₹${monthlyIncome - totalNeeds - totalWants}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            (monthlyIncome - totalNeeds - totalWants) >=
                                savingsGoal
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Goal: Keep ₹$savingsGoal+ for emergencies',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitBudget,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Submit Budget 📤'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventScreen() {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentEvent?.emoji ?? '',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                currentEvent?.name ?? 'Event',
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (currentEvent!.amount > 0)
                Text(
                  'Unexpected expense: ₹${currentEvent!.amount}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  'No extra cost this month! Lucky! 🍀',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _showResults,
                child: const Text('See Results →'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final bool won = remaining >= savingsGoal;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(won ? '🎉' : '😔', style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  Text(
                    won ? 'Budget Master!' : 'Try Again!',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    won
                        ? 'Great! You saved ₹$remaining this month!'
                        : 'You only have ₹$remaining. Goal was ₹$savingsGoal+.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (won)
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
                  // Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Income', '₹$monthlyIncome'),
                        _buildSummaryRow('Needs', '-₹$totalNeeds'),
                        _buildSummaryRow('Wants', '-₹$totalWants'),
                        if (emergencyAmount > 0)
                          _buildSummaryRow(
                            '${currentEvent!.emoji} Emergency',
                            '-₹$emergencyAmount',
                          ),
                        const Divider(),
                        _buildSummaryRow(
                          'Savings',
                          '₹$remaining',
                          isTotal: true,
                          isPositive: won,
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

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isPositive = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? (isPositive ? Colors.green : Colors.red)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Data Classes
class BudgetItem {
  final String id;
  final String name;
  final String emoji;
  final int amount;

  const BudgetItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.amount,
  });
}

class GameEvent {
  final String id;
  final String name;
  final String emoji;
  final int amount;

  const GameEvent({
    required this.id,
    required this.name,
    required this.emoji,
    required this.amount,
  });
}

const List<BudgetItem> needs = [
  BudgetItem(id: 'rent', name: 'Rent', emoji: '🏠', amount: 3000),
  BudgetItem(id: 'food', name: 'Food', emoji: '🍚', amount: 2000),
  BudgetItem(id: 'electricity', name: 'Electricity', emoji: '💡', amount: 500),
  BudgetItem(id: 'school', name: 'School Fees', emoji: '📚', amount: 1500),
];

const List<BudgetItem> wants = [
  BudgetItem(id: 'movie', name: 'Movie', emoji: '🎬', amount: 300),
  BudgetItem(id: 'mobile', name: 'Mobile Recharge', emoji: '📱', amount: 500),
  BudgetItem(id: 'eating', name: 'Eating Outside', emoji: '🍕', amount: 600),
  BudgetItem(id: 'clothes', name: 'New Clothes', emoji: '👕', amount: 1200),
];

const List<GameEvent> events = [
  GameEvent(id: 'medical', name: 'Medical Emergency', emoji: '🏥', amount: 800),
  GameEvent(id: 'phone', name: 'Phone Repair', emoji: '📱🔧', amount: 600),
  GameEvent(id: 'none', name: 'No Emergency', emoji: '✨', amount: 0),
];
