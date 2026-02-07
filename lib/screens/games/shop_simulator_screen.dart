import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/game_service.dart';
import 'dart:math';

class ShopSimulatorScreen extends StatefulWidget {
  const ShopSimulatorScreen({super.key});

  @override
  State<ShopSimulatorScreen> createState() => _ShopSimulatorScreenState();
}

class _ShopSimulatorScreenState extends State<ShopSimulatorScreen> {
  // Game Constants
  static const int maxCups = 50;
  static const int profitTarget = 50;
  static const int maxRounds = 3;
  static const int rewardXP = 30;

  // Costs
  final int costTeaLeaves = 50;
  final int costMilk = 40;
  final int costSugar = 20;
  int get totalInvestment => costTeaLeaves + costMilk + costSugar; // 110

  // State
  int currentRound = 1;
  int totalProfit = 0;
  double selectedPrice = 10;
  String gameState = 'setup'; // setup, result, won, lost

  Map<String, dynamic>? roundResult;
  List<Map<String, dynamic>> roundHistory = [];

  // Data
  final Map<int, Map<String, dynamic>> priceDemand = {
    5: {'customers': 45, 'label': 'Very Cheap'},
    6: {'customers': 40, 'label': 'Cheap'},
    7: {'customers': 35, 'label': 'Budget'},
    8: {'customers': 30, 'label': 'Fair'},
    9: {'customers': 25, 'label': 'Moderate'},
    10: {'customers': 20, 'label': 'Standard'},
    11: {'customers': 18, 'label': 'Standard'},
    12: {'customers': 15, 'label': 'Expensive'},
    13: {'customers': 12, 'label': 'Expensive'},
    14: {'customers': 10, 'label': 'Very Expensive'},
    15: {'customers': 8, 'label': 'Premium'},
  };

  final List<Map<String, dynamic>> events = [
    {
      'id': 'rain',
      'name': 'Rainy Day ☔',
      'effect': 'bonus',
      'desc': 'More customers want tea!',
      'mod': 1.3,
    },
    {
      'id': 'sunny',
      'name': 'Hot Day ☀️',
      'effect': 'penalty',
      'desc': 'Less demand today',
      'mod': 0.7,
    },
    {
      'id': 'spoiled',
      'name': 'Milk Spoiled 🥛❌',
      'effect': 'waste',
      'desc': 'Lost ₹40 milk!',
      'wastage': 40,
    },
    {
      'id': 'festival',
      'name': 'Festival 🎉',
      'effect': 'bonus',
      'desc': 'Big celebration!',
      'mod': 1.5,
    },
    {
      'id': 'normal',
      'name': 'Normal Day 📅',
      'effect': 'none',
      'desc': 'Regular business',
      'mod': 1.0,
    },
  ];

  void runDay() {
    // 1. Get Event
    final event = events[Random().nextInt(events.length)];

    // 2. Calculate Base Demand
    int price = selectedPrice.round();
    int baseCustomers = priceDemand[price]?['customers'] ?? 20;

    // Nearest neighbor interpolation for slider values not in map
    if (!priceDemand.containsKey(price)) {
      // Simple fallback
      baseCustomers = 20;
    }

    // 3. Apply modifier
    double modifier = (event['mod'] as num?)?.toDouble() ?? 1.0;
    int actualCustomers = (baseCustomers * modifier).round();
    actualCustomers = min(actualCustomers, maxCups); // Cap at max capacity

    // 4. Financials
    int revenue = actualCustomers * price;
    int investment = totalInvestment;

    if (event['effect'] == 'waste') {
      investment += (event['wastage'] as int? ?? 0);
    }

    int profit = revenue - investment;

    // 5. Update State
    final result = {
      'round': currentRound,
      'price': price,
      'customers': actualCustomers,
      'revenue': revenue,
      'investment': investment,
      'profit': profit,
      'event': event,
    };

    setState(() {
      roundResult = result;
      roundHistory.add(result);
      totalProfit += profit;
      gameState = 'result';
    });
  }

  void nextRound() {
    if (currentRound >= maxRounds) {
      bool won = totalProfit >= profitTarget;
      setState(() {
        gameState = won ? 'won' : 'lost';
      });
      if (won) {
        // Award XP
        context.read<GameService>().awardMiniGameXP(rewardXP);
      }
    } else {
      setState(() {
        currentRound++;
        gameState = 'setup';
        roundResult = null;
      });
    }
  }

  void resetGame() {
    setState(() {
      currentRound = 1;
      totalProfit = 0;
      selectedPrice = 10;
      gameState = 'setup';
      roundResult = null;
      roundHistory = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tea Shop Simulator'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusBar(),
            const SizedBox(height: 20),
            if (gameState == 'setup') _buildSetup(),
            if (gameState == 'result') _buildResult(),
            if (gameState == 'won' || gameState == 'lost') _buildGameOver(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Day $currentRound / $maxRounds',
            style: AppTypography.titleMedium,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Profit: ₹$totalProfit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: totalProfit >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const Text(
                'Target: ₹50',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetup() {
    int price = selectedPrice.round();
    String demandLabel = priceDemand[price]?['label'] ?? 'Unknown';
    int estCustomers = priceDemand[price]?['customers'] ?? 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCard(
          title: 'Daily Investment',
          child: Column(
            children: [
              _row('Tea Leaves', '₹$costTeaLeaves'),
              _row('Milk', '₹$costMilk'),
              _row('Sugar', '₹$costSugar'),
              const Divider(),
              _row('Total Cost', '₹$totalInvestment', isBold: true),
              const SizedBox(height: 8),
              const Text(
                'Capacity: 50 cups max',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildCard(
          title: 'Set Price: ₹$price',
          child: Column(
            children: [
              Slider(
                value: selectedPrice,
                min: 5,
                max: 15,
                divisions: 10,
                activeColor: AppColors.primary,
                label: '₹$price',
                onChanged: (val) => setState(() => selectedPrice = val),
              ),
              Text('Expected Demand: ~$estCustomers customers'),
              Text(
                demandLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: runDay,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '🛒 Open Shop',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    if (roundResult == null) return const SizedBox.shrink();

    final r = roundResult!;
    final event = r['event'];
    bool isProfit = r['profit'] > 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Text(
                event['name'].split(' ')[0],
                style: const TextStyle(fontSize: 24),
              ), // Emoji rough hack
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(event['desc']),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildCard(
          title: 'Day Results',
          child: Column(
            children: [
              _row('Customers', '${r['customers']}'),
              _row('Revenue', '₹${r['revenue']}'),
              _row('Costs', '₹${r['investment']}'),
              const Divider(),
              _row(
                isProfit ? 'PROFIT' : 'LOSS',
                '₹${r['profit']}',
                isBold: true,
                color: isProfit ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: nextRound,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            currentRound >= maxRounds ? 'See Final Results' : 'Next Day ->',
          ),
        ),
      ],
    );
  }

  Widget _buildGameOver() {
    bool isWon = gameState == 'won';
    return Center(
      child: Column(
        children: [
          Text(isWon ? '🎉' : '😔', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            isWon ? 'Great Business!' : 'Try Again!',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text('Total Profit: ₹$totalProfit'),
          if (isWon)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '+30 XP Earned!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: resetGame, child: const Text('Play Again')),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Hub'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          const Divider(),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
