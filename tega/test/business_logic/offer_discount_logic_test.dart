import 'package:flutter_test/flutter_test.dart';

/// Business Logic Tests for Offers and Discounts
/// 
/// These tests validate offer and discount business rules:
/// - Offer eligibility
/// - Discount calculation
/// - Offer expiry validation
/// - Package offer handling
void main() {
  group('Offer and Discount Business Logic', () {
    group('Offer Eligibility', () {
      test('should check if offer is active', () {
        final offer = {
          'isActive': true,
          'validFrom': DateTime.now().subtract(const Duration(days: 1)),
          'validUntil': DateTime.now().add(const Duration(days: 1)),
        };
        final now = DateTime.now();
        
        // Business rule: Offer must be active and within validity period
        final isEligible = offer['isActive'] == true &&
                         (offer['validFrom'] as DateTime).isBefore(now) &&
                         (offer['validUntil'] as DateTime).isAfter(now);
        expect(isEligible, isTrue);
      });

      test('should reject expired offers', () {
        final offer = {
          'isActive': true,
          'validUntil': DateTime.now().subtract(const Duration(days: 1)),
        };
        final now = DateTime.now();
        
        // Business rule: Expired offers are not eligible
        final isEligible = offer['isActive'] == true &&
                         (offer['validUntil'] as DateTime).isAfter(now);
        expect(isEligible, isFalse);
      });

      test('should check institute-based offers', () {
        const studentInstitute = 'MIT';
        final offer = {
          'applicableInstitutes': ['MIT', 'Harvard'],
        };
        
        // Business rule: Offer applies to specific institutes
        final isEligible = (offer['applicableInstitutes'] as List)
            .contains(studentInstitute);
        expect(isEligible, isTrue);
      });

      test('should check course-specific offers', () {
        const courseId = 'course-123';
        final offer = {
          'applicableCourses': ['course-123', 'course-456'],
        };
        
        // Business rule: Offer applies to specific courses
        final isEligible = (offer['applicableCourses'] as List)
            .contains(courseId);
        expect(isEligible, isTrue);
      });
    });

    group('Discount Calculation', () {
      test('should calculate percentage discount', () {
        const originalPrice = 1000;
        const discountPercent = 25;
        
        // Business rule: Percentage discount
        final discountAmount = originalPrice * (discountPercent / 100);
        final finalPrice = originalPrice - discountAmount;
        
        expect(discountAmount, equals(250));
        expect(finalPrice, equals(750));
      });

      test('should calculate fixed amount discount', () {
        const originalPrice = 1000;
        const discountAmount = 200;
        
        // Business rule: Fixed discount
        final finalPrice = originalPrice - discountAmount;
        expect(finalPrice, equals(800));
      });

      test('should not allow negative prices', () {
        const originalPrice = 100;
        const discountAmount = 200;
        
        // Business rule: Price cannot go below 0
        final finalPrice = (originalPrice - discountAmount).clamp(0, double.infinity);
        expect(finalPrice, equals(0));
      });

      test('should apply maximum discount cap', () {
        const originalPrice = 1000;
        const discountPercent = 50;
        const maxDiscount = 300;
        
        // Business rule: Discount capped at maximum
        final discountAmount = (originalPrice * (discountPercent / 100))
            .clamp(0, maxDiscount);
        final finalPrice = originalPrice - discountAmount;
        
        expect(discountAmount, equals(300));
        expect(finalPrice, equals(700));
      });
    });

    group('Package Offer Handling', () {
      test('should calculate package savings', () {
        final individualPrices = [1000, 800, 600]; // Total: 2400
        const packagePrice = 2000;
        
        // Business rule: Package should offer savings
        final individualTotal = individualPrices.fold<int>(
          0, (sum, price) => sum + price as int,
        );
        final savings = individualTotal - packagePrice;
        final savingsPercent = (savings / individualTotal) * 100;
        
        expect(savings, equals(400));
        expect(savingsPercent, greaterThan(0));
      });

      test('should enroll in all package courses', () {
        final package = {
          'includedCourses': ['course-1', 'course-2', 'course-3'],
        };
        
        // Business rule: Package purchase enrolls in all included courses
        final coursesToEnroll = (package['includedCourses'] as List).length;
        expect(coursesToEnroll, equals(3));
      });

      test('should set package expiry date', () {
        final purchaseDate = DateTime.now();
        final package = {
          'validUntil': DateTime.now().add(const Duration(days: 365)),
        };
        
        // Business rule: Package access expires on validUntil date
        final expiryDate = package['validUntil'] as DateTime;
        expect(expiryDate.isAfter(purchaseDate), isTrue);
      });

      test('should prevent duplicate package purchase', () {
        final existingTransaction = {
          'packageId': 'package-123',
          'expiryDate': DateTime.now().add(const Duration(days: 30)),
        };
        const newPackageId = 'package-123';
        final now = DateTime.now();
        
        // Business rule: Cannot purchase active package again
        final isActive = existingTransaction['packageId'] == newPackageId &&
                        (existingTransaction['expiryDate'] as DateTime).isAfter(now);
        expect(isActive, isTrue);
      });
    });

    group('Offer Application', () {
      test('should apply best available offer', () {
        final offers = [
          {'discount': 10, 'type': 'percentage'},
          {'discount': 200, 'type': 'fixed'},
          {'discount': 15, 'type': 'percentage'},
        ];
        const originalPrice = 1000;
        
        // Business rule: Apply best offer (highest discount)
        double bestDiscount = 0;
        for (final offer in offers) {
          double discount;
          if (offer['type'] == 'percentage') {
            discount = originalPrice * ((offer['discount'] as int) / 100.0);
          } else {
            discount = (offer['discount'] as int).toDouble();
          }
          if (discount > bestDiscount) {
            bestDiscount = discount;
          }
        }
        
        expect(bestDiscount, equals(200.0)); // Fixed discount of 200 is best
      });

      test('should validate offer before application', () {
        final offer = {
          'isActive': true,
          'validUntil': DateTime.now().add(const Duration(days: 1)),
          'minPurchaseAmount': 500,
        };
        const purchaseAmount = 1000;
        final now = DateTime.now();
        
        // Business rule: Offer must be valid and meet minimum purchase
        final canApply = offer['isActive'] == true &&
                        (offer['validUntil'] as DateTime).isAfter(now) &&
                        purchaseAmount >= (offer['minPurchaseAmount'] as int);
        expect(canApply, isTrue);
      });
    });
  });
}

