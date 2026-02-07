import '../models/scheme.dart';
import '../models/user.dart';

class SchemeMatcherService {
  static List<Scheme> match(
    UserProfile user, {
    required Map<String, dynamic> additionalData,
  }) {
    final schemes = GovernmentSchemes.all;
    List<Scheme> matches = [];

    // Extract additional checked data often needed for matching but not in UserProfile
    bool ownsLand = additionalData['owns_land'] ?? false;
    int income = int.tryParse(additionalData['income'].toString()) ?? 0;
    int age = additionalData['age'] ?? user.age ?? 0;
    String occupation = additionalData['occupation'] ?? user.occupation;
    // Gender is not in UserProfile explicitly as a field in shared snippet (it had occupation/incomeRange).
    // Assuming 'gender' might be passed or added.
    String gender = additionalData['gender'] ?? 'male';

    for (var scheme in schemes) {
      if (scheme.structuredEligibility == null) continue;

      var e = scheme.structuredEligibility!;

      // 1. Age Check
      if (e.containsKey('min_age') && age < e['min_age']) {
        continue;
      }
      if (e.containsKey('max_age') && age > e['max_age']) {
        continue;
      }

      // 2. Income Check
      if (e.containsKey('max_income') && income > e['max_income']) {
        continue;
      }

      // 3. Gender Check
      if (e.containsKey('gender')) {
        if (e['gender'].toString().toLowerCase() != gender.toLowerCase()) {
          continue;
        }
      }

      // 4. Occupation Check
      if (e.containsKey('occupation')) {
        List<String> allowedOccupations = List<String>.from(e['occupation']);
        if (!allowedOccupations.contains(occupation) &&
            !allowedOccupations.contains('any')) {
          continue;
        }
      }

      // 5. Land Check
      if (e.containsKey('owns_land')) {
        bool required = e['owns_land'];
        // If scheme requires land (true) and user doesn't have it -> fail
        if (required && !ownsLand) {
          continue;
        }
        // If scheme requires NO land (false) and user has it -> fail (rare, maybe for landless laborers)
        if (!required && ownsLand && scheme.category == 'worker') {
          // Heuristic: if scheme is specifically for landless, and they have land.
          // However, usually 'owns_land': false means "doesn't matter" or "not required".
          // Let's stick to sp1 logic:
          // sp1: if required && !user.ownsLand -> continue.
          // It didn't seemingly penalize owning land unless explicit.
        }
      }

      matches.add(scheme);
    }
    return matches;
  }
}
