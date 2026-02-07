import 'package:flutter_test/flutter_test.dart';
import 'package:fintech_sbmp/services/scheme_matcher_service.dart';
import 'package:fintech_sbmp/models/user.dart';
import 'package:fintech_sbmp/models/scheme.dart';

void main() {
  group('SchemeMatcherService Tests', () {
    test('Farmer profile matches PM-KISAN', () {
      final user = UserProfile(
        id: '1',
        name: 'Test Farmer',
        language: 'en',
        occupation: 'farmer',
        incomeRange: '10000',
        createdAt: DateTime.now(),
      );

      final matches = SchemeMatcherService.match(
        user,
        additionalData: {
          'age': 30,
          'occupation': 'farmer',
          'owns_land': true,
          'income': 10000,
        },
      );

      expect(matches.any((s) => s.id == 'pm_kisan'), true);
    });

    test('Student profile matches Scholarship', () {
      final user = UserProfile(
        id: '2',
        name: 'Test Student',
        language: 'en',
        occupation: 'student',
        incomeRange: '0',
        createdAt: DateTime.now(),
      );

      final matches = SchemeMatcherService.match(
        user,
        additionalData: {'age': 18, 'occupation': 'student'},
      );

      expect(matches.any((s) => s.id == 'scholarship'), true);
    });

    test('High income excludes income-capped schemes', () {
      final user = UserProfile(
        id: '3',
        name: 'Rich Person',
        language: 'en',
        occupation: 'business',
        incomeRange: '1000000',
        createdAt: DateTime.now(),
      );

      final matches = SchemeMatcherService.match(
        user,
        additionalData: {
          'age': 30,
          'occupation': 'business',
          'income': 1000000,
        },
      );

      // PM-SYM has explicitly max_income 15000 in my setup
      expect(matches.any((s) => s.id == 'pm_sym'), false);
    });
  });
}
