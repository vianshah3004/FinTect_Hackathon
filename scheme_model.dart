import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// --- Models ---

class UserProfile {
  int age;
  String gender;
  String occupation;
  int income;
  String state;
  bool ownsLand;

  UserProfile({
    required this.age,
    required this.gender,
    required this.occupation,
    required this.income,
    required this.state,
    required this.ownsLand,
  });
}

class Scheme {
  final String id;
  final String name;
  final String description;
  final String benefits;
  final List<String> documents;
  final String howToApply;
  final String nearestOffice;
  final Map<String, dynamic> eligibility;
  final Map<String, dynamic> _json; // Store full JSON for multilingual access

  Scheme({
    required this.id,
    required this.name,
    required this.description,
    required this.benefits,
    required this.documents,
    required this.howToApply,
    required this.nearestOffice,
    required this.eligibility,
    required Map<String, dynamic> json,
  }) : _json = json;

  // Multilingual getters
  String getName(String lang) => _json['name_$lang'] ?? name;
  String getDescription(String lang) =>
      _json['description_$lang'] ?? description;
  String getBenefits(String lang) => _json['benefits_$lang'] ?? benefits;
  String getHowToApply(String lang) =>
      _json['how_to_apply_$lang'] ?? howToApply;

  // For backward compatibility
  String? get nameHi => _json['name_hi'];
  String? get descHi => _json['description_hi'];

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      benefits: json['benefits'] ?? '',
      documents: List<String>.from(json['documents'] ?? []),
      howToApply: json['how_to_apply'] ?? '',
      nearestOffice: json['nearest_office'] ?? '',
      eligibility: json['eligibility'] ?? {},
      json: json,
    );
  }
}

// --- Matcher Logic ---

class SchemeMatcher {
  List<Scheme> _schemes = [];

  Future<void> loadSchemes() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/schemes.json',
      );
      final List<dynamic> data = json.decode(response);
      _schemes = data.map((e) => Scheme.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error loading schemes: $e");
    }
  }

  List<Scheme> match(UserProfile user) {
    List<Scheme> matches = [];

    for (var scheme in _schemes) {
      var e = scheme.eligibility;

      // 1. Age Check
      if (e.containsKey('min_age') && user.age < e['min_age']) {
        continue;
      }
      if (e.containsKey('max_age') && user.age > e['max_age']) {
        continue;
      }

      // 2. Income Check
      if (e.containsKey('max_income') && user.income > e['max_income']) {
        continue;
      }

      // 3. Gender Check
      if (e.containsKey('gender')) {
        if (e['gender'].toString().toLowerCase() != user.gender.toLowerCase()) {
          continue;
        }
      }

      // 4. Occupation Check
      if (!e['occupation'].contains(user.occupation) &&
          !e['occupation'].contains('any')) {
        continue;
      }

      // 5. State Check
      if (e.containsKey('state') && e['state'] != 'All') {
        if (e['state'].toString().toLowerCase() != user.state.toLowerCase()) {
          continue;
        }
      }

      // 6. Land Check
      if (e.containsKey('owns_land')) {
        bool required = e['owns_land'];
        if (required && !user.ownsLand) {
          continue;
        }
        // Strict check: if owns_land is true, user MUST have land.
        // If false, it usually means 'Any', but for KCC/Farmers let's assume correlation.
      }

      matches.add(scheme);
    }
    return matches;
  }
}
