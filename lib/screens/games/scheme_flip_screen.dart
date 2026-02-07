import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../config/theme.dart';
import '../../services/game_service.dart';

class SchemeFlipScreen extends StatefulWidget {
  const SchemeFlipScreen({super.key});

  @override
  State<SchemeFlipScreen> createState() => _SchemeFlipScreenState();
}

class _SchemeFlipScreenState extends State<SchemeFlipScreen> {
  static const int rewardXP = 20;

  List<FlipCardData> cards = [];
  List<FlipCardData> flippedCards = [];
  Set<String> matchedPairs = {};
  int moves = 0;
  bool isChecking = false;
  bool isGameOver = false;
  SchemeFlipInfo? matchedInfoScheme;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _initializeGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // Generate identical pairs
    final pairs = flipSchemes
        .flatMap(
          (scheme) => [
            FlipCardData(
              id: '${scheme.id}-1',
              pairId: scheme.id,
              name: scheme.name,
              scheme: scheme,
            ),
            FlipCardData(
              id: '${scheme.id}-2',
              pairId: scheme.id,
              name: scheme.name,
              scheme: scheme,
            ),
          ],
        )
        .toList();

    pairs.shuffle();

    setState(() {
      cards = pairs;
      flippedCards = [];
      matchedPairs = {};
      moves = 0;
      isGameOver = false;
      isChecking = false;
      matchedInfoScheme = null;
    });
  }

  void _onCardTap(FlipCardData card) {
    if (isChecking ||
        flippedCards.contains(card) ||
        matchedPairs.contains(card.pairId))
      return;

    setState(() {
      flippedCards.add(card);
    });

    if (flippedCards.length == 2) {
      setState(() {
        moves++;
        isChecking = true;
      });
      _checkForMatch();
    }
  }

  void _checkForMatch() {
    final card1 = flippedCards[0];
    final card2 = flippedCards[1];

    if (card1.pairId == card2.pairId && card1.id != card2.id) {
      // Match!
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          matchedPairs.add(card1.pairId);
          matchedInfoScheme = card1.scheme;
          flippedCards = [];
          isChecking = false;
        });

        if (matchedPairs.length == flipSchemes.length) {
          _gameOver();
        }
      });
    } else {
      // No match
      Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          flippedCards = [];
          isChecking = false;
        });
      });
    }
  }

  void _gameOver() {
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        isGameOver = true;
      });
      _confettiController.play();
      context.read<GameService>().awardMiniGameXP(rewardXP);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver) return _buildResultScreen();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scheme Flip'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Moves: $moves',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Find Identical Pairs! 🎴',
                  style: AppTypography.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final isFlipped =
                        flippedCards.contains(card) ||
                        matchedPairs.contains(card.pairId);

                    return GestureDetector(
                      onTap: () => _onCardTap(card),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isFlipped ? Colors.white : Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: isFlipped
                              ? Border.all(color: Colors.orange, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: isFlipped
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        card.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                )
                              : const Text('❓', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          if (matchedInfoScheme != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✅ Discovered!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        matchedInfoScheme!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        matchedInfoScheme!.description,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            matchedInfoScheme = null;
                          });
                        },
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
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
                  const Text('🎉', style: TextStyle(fontSize: 80)),
                  Text(
                    'Excellent Discovery!',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You found all schemes in $moves moves!',
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
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: flipSchemes.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 160,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                flipSchemes[index].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  flipSchemes[index].description,
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                        onPressed: _initializeGame,
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
class FlipCardData {
  final String id;
  final String pairId;
  final String name;
  final SchemeFlipInfo scheme;

  FlipCardData({
    required this.id,
    required this.pairId,
    required this.name,
    required this.scheme,
  });
}

class SchemeFlipInfo {
  final String id;
  final String name;
  final String description;

  const SchemeFlipInfo({
    required this.id,
    required this.name,
    required this.description,
  });
}

// Helper extension
extension FlatMap<T> on List<T> {
  List<E> flatMap<E>(List<E> Function(T) f) => expand(f).toList();
}

const List<SchemeFlipInfo> flipSchemes = [
  SchemeFlipInfo(
    id: 'pmkisan',
    name: 'PM-KISAN',
    description: 'Farmers receive ₹6000 every year directly to buy seeds.',
  ),
  SchemeFlipInfo(
    id: 'mudra',
    name: 'Mudra Loan',
    description: 'Get a loan up to ₹50,000 to start your own small business.',
  ),
  SchemeFlipInfo(
    id: 'sukanya',
    name: 'Sukanya',
    description:
        'Save money for your daughter\'s education with extra interest.',
  ),
  SchemeFlipInfo(
    id: 'kcc',
    name: 'KCC',
    description:
        'Kisan Credit Card gives farmers easy loans at low interest rates.',
  ),
  SchemeFlipInfo(
    id: 'pmjjby',
    name: 'PMJJBY',
    description: 'Pay ₹436/year and your family gets ₹2 lakh life insurance.',
  ),
  SchemeFlipInfo(
    id: 'apy',
    name: 'APY',
    description: 'Atal Pension Yojana gives you monthly pension after age 60.',
  ),
];
