import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../config/theme.dart';
import '../../services/game_service.dart';

class SchemeMatcherScreen extends StatefulWidget {
  const SchemeMatcherScreen({super.key});

  @override
  State<SchemeMatcherScreen> createState() => _SchemeMatcherScreenState();
}

class _SchemeMatcherScreenState extends State<SchemeMatcherScreen> {
  static const int rewardXP = 20;

  List<SchemeCardData> cards = [];
  List<SchemeCardData> flippedCards = [];
  Set<String> matchedPairs = {};
  int moves = 0;
  bool isChecking = false;
  bool isGameOver = false;
  Scheme? matchedInfoScheme;
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
    final pairs = schemes
        .flatMap(
          (scheme) => [
            SchemeCardData(
              id: '${scheme.id}-name',
              pairId: scheme.id,
              type: CardType.name,
              content: scheme.name,
              scheme: scheme,
            ),
            SchemeCardData(
              id: '${scheme.id}-benefit',
              pairId: scheme.id,
              type: CardType.benefit,
              content: scheme.benefit,
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

  void _onCardTap(SchemeCardData card) {
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

    if (card1.pairId == card2.pairId && card1.type != card2.type) {
      // Match!
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          matchedPairs.add(card1.pairId);
          matchedInfoScheme = card1.scheme;
          flippedCards = [];
          isChecking = false;
        });

        if (matchedPairs.length == schemes.length) {
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
        title: const Text('Scheme Matcher'),
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
                  'Match the Scheme with its Benefit! 🎯',
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
                          color: isFlipped ? Colors.white : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: isFlipped
                              ? Border.all(color: AppColors.primary, width: 2)
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
                                        card.content,
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
                        '✅ Match Found!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${matchedInfoScheme!.name} → ${matchedInfoScheme!.benefit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                        child: const Text('Continue Playing'),
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
                  Text('Amazing Memory!', style: AppTypography.headlineMedium),
                  const SizedBox(height: 16),
                  Text(
                    'You matched all schemes in $moves moves!',
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
                      itemCount: schemes.length,
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
                                schemes[index].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                schemes[index].benefit,
                                style: const TextStyle(color: Colors.blue),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  schemes[index].description,
                                  style: const TextStyle(fontSize: 10),
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
enum CardType { name, benefit }

class SchemeCardData {
  final String id;
  final String pairId;
  final CardType type;
  final String content;
  final Scheme scheme;

  SchemeCardData({
    required this.id,
    required this.pairId,
    required this.type,
    required this.content,
    required this.scheme,
  });
}

class Scheme {
  final String id;
  final String name;
  final String benefit;
  final String description;

  const Scheme({
    required this.id,
    required this.name,
    required this.benefit,
    required this.description,
  });
}

// Helper extension
extension FlatMap<T> on List<T> {
  List<E> flatMap<E>(List<E> Function(T) f) => expand(f).toList();
}

const List<Scheme> schemes = [
  Scheme(
    id: 'pmkisan',
    name: 'PM-KISAN',
    benefit: '₹6000/year',
    description:
        'Farmers receive ₹6000 every year directly in their bank account.',
  ),
  Scheme(
    id: 'mudra',
    name: 'Mudra Loan',
    benefit: '₹50k Loan',
    description: 'Get a loan up to ₹50,000 to start your own small business.',
  ),
  Scheme(
    id: 'sukanya',
    name: 'Sukanya',
    benefit: 'Girl Education',
    description: 'Save money for your daughter\'s education and marriage.',
  ),
  Scheme(
    id: 'kcc',
    name: 'KCC',
    benefit: 'Farmer Loan',
    description:
        'Kisan Credit Card gives farmers easy loans at low interest rates.',
  ),
  Scheme(
    id: 'pmjjby',
    name: 'PMJJBY',
    benefit: 'Life Insurance',
    description: 'Pay just ₹436/year and your family gets ₹2 lakh coverage.',
  ),
  Scheme(
    id: 'pmsby',
    name: 'PMSBY',
    benefit: 'Accident Cover',
    description:
        'For just ₹20/year, get ₹2 lakh coverage if you have an accident.',
  ),
];
