import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../config/theme.dart';
import '../../services/game_service.dart';

class RupeeSaverScreen extends StatefulWidget {
  const RupeeSaverScreen({super.key});

  @override
  State<RupeeSaverScreen> createState() => _RupeeSaverScreenState();
}

class _RupeeSaverScreenState extends State<RupeeSaverScreen> {
  // Game Constants
  static const int dailyIncome = 300;
  static const int minSavingsGoal = 50;
  static const int totalDays = 7;
  static const String gameId = 'rupee-saver';
  static const int rewardXP = 20;

  // State
  int currentDay = 1;
  int totalSavings = 0;
  int dailySpent = 0;
  List<Item> availableItems = [];
  List<Item> spendBasket = [];
  List<Item> saveJar = [];
  bool isGameOver = false;
  bool hasWon = false;
  List<DailyHistory> history = [];

  late ConfettiController _confettiController;

  final List<Item> allItems = [
    Item(id: 'tea', name: 'Tea', emoji: '☕', price: 10, type: ItemType.need),
    Item(
      id: 'vegetables',
      name: 'Vegetables',
      emoji: '🥬',
      price: 50,
      type: ItemType.need,
    ),
    Item(
      id: 'cigarettes',
      name: 'Cigarettes',
      emoji: '🚬',
      price: 20,
      type: ItemType.want,
    ),
    Item(
      id: 'biscuits',
      name: 'Biscuits',
      emoji: '🍪',
      price: 15,
      type: ItemType.want,
    ),
    Item(
      id: 'transport',
      name: 'Transport',
      emoji: '🚌',
      price: 30,
      type: ItemType.need,
    ),
    Item(
      id: 'samosa',
      name: 'Samosa',
      emoji: '🥟',
      price: 15,
      type: ItemType.want,
    ),
    Item(
      id: 'medicine',
      name: 'Medicine',
      emoji: '💊',
      price: 40,
      type: ItemType.need,
    ),
    Item(
      id: 'chips',
      name: 'Chips',
      emoji: '🍟',
      price: 20,
      type: ItemType.want,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _startNewDay();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _startNewDay() {
    setState(() {
      dailySpent = 0;
      spendBasket = [];
      saveJar = [];
      // Pick 5 random items
      final shuffled = List<Item>.from(allItems)..shuffle();
      availableItems = shuffled.take(5).toList();
    });
  }

  void _onDropSpend(Item item) {
    setState(() {
      spendBasket.add(item);
      availableItems.removeWhere((i) => i.id == item.id);
      dailySpent += item.price;
    });
  }

  void _onDropSave(Item item) {
    setState(() {
      saveJar.add(item);
      availableItems.removeWhere((i) => i.id == item.id);
    });
  }

  void _endDay() {
    final dailySaved = dailyIncome - dailySpent;

    setState(() {
      history.add(
        DailyHistory(day: currentDay, saved: dailySaved, spent: dailySpent),
      );
      totalSavings += dailySaved;

      if (currentDay >= totalDays) {
        _endGame();
      } else {
        currentDay++;
        _startNewDay();
      }
    });
  }

  void _endGame() {
    final avgSavings = totalSavings / totalDays;
    final won = avgSavings >= minSavingsGoal;

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
      currentDay = 1;
      totalSavings = 0;
      isGameOver = false;
      hasWon = false;
      history = [];
      _startNewDay();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver) {
      return _buildGameOverScreen();
    }

    final dailySaved = dailyIncome - dailySpent;
    final metGoal = dailySaved >= minSavingsGoal;
    final canEndDay = availableItems.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rupee Saver'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Day Info Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day $currentDay of $totalDays',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Income: ₹$dailyIncome',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Spent',
                        '₹$dailySpent',
                        Colors.red.shade100,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Saved',
                        '₹$dailySaved',
                        metGoal
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        metGoal
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        '₹$totalSavings',
                        Colors.blue.shade100,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Goal Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: metGoal ? Colors.green.shade50 : Colors.amber.shade50,
            child: Text(
              metGoal
                  ? '✅ Great! You\'re saving ₹$dailySaved (Goal: ₹$minSavingsGoal+)'
                  : '⚠️ Save at least ₹$minSavingsGoal today!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: metGoal ? Colors.green.shade800 : Colors.amber.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Drop Zones
          Expanded(
            child: Row(
              children: [
                // Spend Zone
                Expanded(
                  child: DragTarget<Item>(
                    onWillAccept: (_) => true,
                    onAccept: _onDropSpend,
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: candidateData.isNotEmpty
                                ? Colors.red
                                : Colors.red.shade200,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '🧺 SPEND',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: spendBasket.length,
                                itemBuilder: (context, index) {
                                  final item = spendBasket[index];
                                  return ListTile(
                                    dense: true,
                                    leading: Text(item.emoji),
                                    title: Text(item.name),
                                    trailing: Text('₹${item.price}'),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Total: ₹$dailySpent',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Save Zone
                Expanded(
                  child: DragTarget<Item>(
                    onWillAccept: (_) => true,
                    onAccept: _onDropSave,
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: candidateData.isNotEmpty
                                ? Colors.green
                                : Colors.green.shade200,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '🏺 SAVE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: saveJar.length,
                                itemBuilder: (context, index) {
                                  final item = saveJar[index];
                                  return ListTile(
                                    dense: true,
                                    leading: Text(item.emoji),
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    trailing: const Text(
                                      'Saved!',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Saved: ₹$dailySaved',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Draggable Items
          Container(
            height: 140,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (availableItems.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Drag items to Spend or Save:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableItems.length,
                      itemBuilder: (context, index) {
                        final item = availableItems[index];
                        return Draggable<Item>(
                          data: item,
                          feedback: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            child: _buildItemCard(item),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: _buildItemCard(item),
                          ),
                          child: _buildItemCard(item),
                        );
                      },
                    ),
                  ),
                ] else
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _endDay,
                      icon: const Icon(Icons.check_circle),
                      label: Text('End Day $currentDay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen() {
    final avgSavings = (totalSavings / totalDays).round();

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasWon ? '🎉' : '😔',
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasWon ? 'Congratulations!' : 'Try Again!',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasWon
                        ? 'You saved an average of ₹$avgSavings per day!'
                        : 'You saved only ₹$avgSavings per day. Goal was ₹$minSavingsGoal.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge,
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
                          '💡 What You Learned:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('• Needs are essential (food, transport)'),
                        Text('• Wants can wait (snacks, treats)'),
                        Text('• Small daily savings add up quickly!'),
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

  Widget _buildItemCard(Item item) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            '₹${item.price}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: text.withOpacity(0.8), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

enum ItemType { need, want }

class Item {
  final String id;
  final String name;
  final String emoji;
  final int price;
  final ItemType type;

  Item({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.type,
  });
}

class DailyHistory {
  final int day;
  final int saved;
  final int spent;

  DailyHistory({required this.day, required this.saved, required this.spent});
}
