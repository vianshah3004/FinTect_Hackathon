import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/game_service.dart';
import '../../providers/user_provider.dart';
import 'shop_simulator_screen.dart';
import 'rupee_saver_screen.dart';
import 'interest_magic_screen.dart';
import 'scheme_matcher_screen.dart';
import 'scheme_flip_screen.dart';
import 'budget_builder_screen.dart';
import 'credit_score_hero_screen.dart';

class GamesHubScreen extends StatelessWidget {
  GamesHubScreen({super.key});

  // Bilingual game data
  List<Map<String, dynamic>> _getGames(bool isHindi) => [
    {
      'id': 'shop',
      'name': isHindi ? 'दुकान सिमुलेटर' : 'Shop Simulator',
      'emoji': '🏪',
      'color': AppColors.primary,
      'description': isHindi
          ? 'अपनी चाय की दुकान चलाएं! स्टॉक, कीमत और मुनाफा संभालें।'
          : 'Run your own tea shop! Manage stock, set prices, and make profit.',
      'screen': ShopSimulatorScreen(),
      'xp': 30,
    },
    {
      'id': 'rupee_saver',
      'name': isHindi ? 'रुपया बचाओ' : 'Rupee Saver',
      'emoji': '🏺',
      'color': AppColors.success,
      'description': isHindi
          ? 'जरूरत vs इच्छा में ड्रैग करें। 7 दिन पैसे बचाएं!'
          : 'Drag & drop needs vs wants. Save money for 7 days!',
      'screen': RupeeSaverScreen(),
      'xp': 25,
    },
    {
      'id': 'interest_magic',
      'name': isHindi ? 'ब्याज का जादू' : 'Interest Magic',
      'emoji': '🌳',
      'color': AppColors.info,
      'description': isHindi
          ? 'देखें पैसा कैसे बढ़ता है! बैंक vs साहूकार की तुलना।'
          : 'See how money grows! Compare Bank vs Moneylender.',
      'screen': InterestMagicScreen(),
      'xp': 20,
    },
    {
      'id': 'scheme_flip',
      'name': isHindi ? 'योजना फ्लिप' : 'Scheme Flip',
      'emoji': '🎴',
      'color': AppColors.primaryAccent,
      'description': isHindi
          ? 'एक जैसी योजनाओं के जोड़े खोजें। याददाश्त परखें!'
          : 'Find pairs of identical schemes. Test your memory!',
      'screen': SchemeFlipScreen(),
      'xp': 20,
    },
    {
      'id': 'budget_builder',
      'name': isHindi ? 'बजट बिल्डर' : 'Budget Builder',
      'emoji': '📝',
      'color': AppColors.primaryLight,
      'description': isHindi
          ? 'मासिक बजट बनाएं। अचानक खर्चे संभालें!'
          : 'Build a monthly budget. Handle surprise expenses!',
      'screen': BudgetBuilderScreen(),
      'xp': 30,
    },
    {
      'id': 'credit_score',
      'name': isHindi ? 'क्रेडिट हीरो' : 'Credit Hero',
      'emoji': '🦸',
      'color': AppColors.error,
      'description': isHindi
          ? 'स्मार्ट चुनाव करें और क्रेडिट स्कोर बढ़ाएं!'
          : 'Make smart choices to boost your credit score!',
      'screen': CreditScoreHeroScreen(),
      'xp': 30,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isHindi = userProvider.language == 'hi';
    final games = _getGames(isHindi);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isHindi ? 'फाइनेंस क्वेस्ट' : 'Finance Quest'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, isHindi),
            const SizedBox(height: 24),
            Text(
              isHindi ? 'अपना गेम चुनें' : 'Choose Your Adventure',
              style: AppTypography.headlineMedium.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return _buildGameCard(context, games[index], isHindi);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isHindi) {
    final gameService = context.watch<GameService>();
    final points = gameService.player?.xp ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🎮', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'फाइनेंस गेम्स' : 'Finance Games',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  isHindi
                      ? 'खेलो और सीखो! XP: $points'
                      : 'Play & Learn! XP: $points',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    Map<String, dynamic> game,
    bool isHindi,
  ) {
    final Color gameColor = game['color'] as Color;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => game['screen']),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gameColor.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: gameColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: gameColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(game['emoji'], style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 12),
            Text(
              game['name'],
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              game['description'],
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${game['xp']} XP',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
