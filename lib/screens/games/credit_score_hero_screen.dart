import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../config/theme.dart';
import '../../services/game_service.dart';

class CreditScoreHeroScreen extends StatefulWidget {
  const CreditScoreHeroScreen({super.key});

  @override
  State<CreditScoreHeroScreen> createState() => _CreditScoreHeroScreenState();
}

class _CreditScoreHeroScreenState extends State<CreditScoreHeroScreen> {
  // Constants
  static const int startScore = 650;
  static const int winScore = 750;
  static const int minScore = 300;
  static const int maxScore = 900;
  static const int rewardXP = 30;

  // State
  int score = startScore;
  int currentScenarioIndex = 0;
  ScenarioChoice? lastChoice;
  bool isGameOver = false;
  bool hasWon = false;
  List<ChoiceRecord> choicesMade = [];

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

  Color get scoreColor {
    if (score >= 750) return Colors.green;
    if (score >= 650) return Colors.orange;
    return Colors.red;
  }

  String get scoreLabel {
    if (score >= 750) return 'Excellent';
    if (score >= 650) return 'Fair';
    return 'Poor';
  }

  void _makeChoice(ScenarioChoice choice) {
    setState(() {
      lastChoice = choice;
      score = (score + choice.impact).clamp(minScore, maxScore);
      choicesMade.add(
        ChoiceRecord(
          scenario: scenarios[currentScenarioIndex].situation,
          choice: choice.text,
          impact: choice.impact,
        ),
      );
    });

    // Wait and proceed
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      if (score >= winScore) {
        _endGame(true);
      } else if (currentScenarioIndex >= scenarios.length - 1) {
        _endGame(score >= winScore);
      } else {
        setState(() {
          currentScenarioIndex++;
          lastChoice = null;
        });
      }
    });
  }

  void _endGame(bool won) {
    setState(() {
      isGameOver = true;
      hasWon = won;
    });

    if (won) {
      _confettiController.play();
      context.read<GameService>().awardMiniGameXP(rewardXP);
    }
  }

  void _resetGame() {
    setState(() {
      score = startScore;
      currentScenarioIndex = 0;
      lastChoice = null;
      isGameOver = false;
      hasWon = false;
      choicesMade = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver) return _buildResultScreen();

    final scenario = scenarios[currentScenarioIndex];
    double progress = (score - minScore) / (maxScore - minScore);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Credit Score Hero'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Score Meter
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('300', style: TextStyle(color: Colors.grey)),
                    Column(
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          scoreLabel,
                          style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text('900', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '🎯 Goal: Reach 750!',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Scenario ${currentScenarioIndex + 1}/${scenarios.length}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Scenario Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          scenario.situation,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (lastChoice == null) ...[
                          ...scenario.choices.map(
                            (choice) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _makeChoice(choice),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                    backgroundColor: Colors.blue.shade50,
                                    foregroundColor: Colors.blue.shade900,
                                  ),
                                  child: Text(
                                    choice.text,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lastChoice!.impact >= 0
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: lastChoice!.impact >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  lastChoice!.feedback,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: lastChoice!.impact >= 0
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lastChoice!.impact >= 0
                                      ? '+${lastChoice!.impact} points'
                                      : '${lastChoice!.impact} points',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: lastChoice!.impact >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                  Text(
                    hasWon ? '🏆' : '📉',
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasWon ? 'Credit Hero!' : 'Keep Learning!',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scoreColor, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text('Final Score'),
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          scoreLabel,
                          style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (hasWon)
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
                  // Lesson Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 Credit Score Tips:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('• Pay all EMIs and bills on time ✅'),
                        Text('• Keep credit usage below 30% 📊'),
                        Text('• Avoid too many loan applications 🚫'),
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
}

// Data Classes
class ChoiceRecord {
  final String scenario;
  final String choice;
  final int impact;

  ChoiceRecord({
    required this.scenario,
    required this.choice,
    required this.impact,
  });
}

class Scenario {
  final int id;
  final String situation;
  final List<ScenarioChoice> choices;

  const Scenario({
    required this.id,
    required this.situation,
    required this.choices,
  });
}

class ScenarioChoice {
  final String text;
  final int impact;
  final String feedback;

  const ScenarioChoice({
    required this.text,
    required this.impact,
    required this.feedback,
  });
}

const List<Scenario> scenarios = [
  Scenario(
    id: 1,
    situation: 'Your EMI payment of ₹2,000 is due today.',
    choices: [
      ScenarioChoice(
        text: '✅ Pay on time',
        impact: 20,
        feedback: 'Great! On-time payments boost your score.',
      ),
      ScenarioChoice(
        text: '❌ Skip this month',
        impact: -40,
        feedback: 'Missed payments hurt your credit badly!',
      ),
    ],
  ),
  Scenario(
    id: 2,
    situation: 'You have a credit card with ₹50,000 limit.',
    choices: [
      ScenarioChoice(
        text: '💳 Use only ₹15,000 (30%)',
        impact: 15,
        feedback: 'Low utilization shows discipline!',
      ),
      ScenarioChoice(
        text: '💥 Max it out (100%)',
        impact: -30,
        feedback: 'High credit usage lowers your score.',
      ),
    ],
  ),
  Scenario(
    id: 3,
    situation: 'Bank offers you a small personal loan of ₹20,000.',
    choices: [
      ScenarioChoice(
        text: '✅ Take and repay on time',
        impact: 25,
        feedback: 'Successful loan repayment builds credit!',
      ),
      ScenarioChoice(
        text: '❌ Take but delay payments',
        impact: -35,
        feedback: 'Delayed payments damage your trust.',
      ),
    ],
  ),
  Scenario(
    id: 4,
    situation: 'You want to buy a phone. Two options:',
    choices: [
      ScenarioChoice(
        text: '💰 Save and pay cash',
        impact: 10,
        feedback: 'No new debt = healthy finances!',
      ),
      ScenarioChoice(
        text: '📱 Take another loan',
        impact: -20,
        feedback: 'Too many loans can hurt your score.',
      ),
    ],
  ),
  Scenario(
    id: 5,
    situation: 'Credit card bill of ₹8,000 is due.',
    choices: [
      ScenarioChoice(
        text: '✅ Pay full amount',
        impact: 20,
        feedback: 'Paying in full avoids interest!',
      ),
      ScenarioChoice(
        text: '⚠️ Pay only minimum',
        impact: -10,
        feedback: 'Minimum payments add interest debt.',
      ),
    ],
  ),
];
