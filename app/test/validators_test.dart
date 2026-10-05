import 'package:agent_post/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Indian mobile number validation', () {
    test('accepts plain 10-digit numbers starting 6-9', () {
      expect(Validators.isValidIndianMobile('9876543210'), isTrue);
      expect(Validators.isValidIndianMobile('6123456789'), isTrue);
    });

    test('accepts numbers with +91 / 0 / spaces / dashes', () {
      expect(Validators.isValidIndianMobile('+91 98765 43210'), isTrue);
      expect(Validators.isValidIndianMobile('91-98765-43210'), isTrue);
      expect(Validators.isValidIndianMobile('098765 43210'), isTrue);
      expect(Validators.isValidIndianMobile('98765-43210'), isTrue);
    });

    test('rejects invalid numbers', () {
      expect(Validators.isValidIndianMobile('1234567890'), isFalse); // starts with 1
      expect(Validators.isValidIndianMobile('5876543210'), isFalse); // starts with 5
      expect(Validators.isValidIndianMobile('987654321'), isFalse); // 9 digits
      expect(Validators.isValidIndianMobile('98765432100'), isFalse); // 11 digits
      expect(Validators.isValidIndianMobile(''), isFalse);
      expect(Validators.isValidIndianMobile(null), isFalse);
      expect(Validators.isValidIndianMobile('abcdefghij'), isFalse);
    });

    test('mobile() field validator gives friendly messages', () {
      expect(Validators.mobile('9876543210'), isNull);
      expect(Validators.mobile(''), isNotNull);
      expect(Validators.mobile('12345'), isNotNull);
    });

    test('optionalMobile() allows empty but validates when filled', () {
      expect(Validators.optionalMobile(''), isNull);
      expect(Validators.optionalMobile(null), isNull);
      expect(Validators.optionalMobile('9876543210'), isNull);
      expect(Validators.optionalMobile('12345'), isNotNull);
    });
  });

  group('Email validation', () {
    test('valid emails pass', () {
      expect(Validators.email('agent@example.com'), isNull);
      expect(Validators.email('a.b+c@sub.example.co.in'), isNull);
    });

    test('invalid emails fail', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });

    test('optionalEmail() allows empty', () {
      expect(Validators.optionalEmail(''), isNull);
      expect(Validators.optionalEmail('agent@example.com'), isNull);
      expect(Validators.optionalEmail('nope'), isNotNull);
    });
  });

  group('Password validation', () {
    test('needs at least 8 characters', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });
  });

  group('Name validation', () {
    test('requires 2-120 characters', () {
      expect(Validators.fullName('Ramesh Patel'), isNull);
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('A'), isNotNull);
      expect(Validators.fullName('x' * 121), isNotNull);
    });
  });

  group('Hex colour validation', () {
    test('accepts #RRGGBB only', () {
      expect(Validators.isValidHexColor('#173B63'), isTrue);
      expect(Validators.isValidHexColor('#0fa3b1'), isTrue);
      expect(Validators.isValidHexColor('173B63'), isFalse); // missing #
      expect(Validators.isValidHexColor('#12345'), isFalse); // too short
      expect(Validators.isValidHexColor('#GGGGGG'), isFalse);
    });
  });

  group('Mobile normalisation', () {
    test('strips spaces, dashes and brackets', () {
      expect(Validators.normalizeMobile('+91 98765-43210'), '+919876543210');
    });
  });
}
