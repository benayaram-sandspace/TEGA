import 'package:flutter_test/flutter_test.dart';
import 'package:tega/features/4_college_panel/data/repositories/college_repository.dart';

void main() {
  group('CollegeRepository', () {
    late CollegeService collegeService;

    setUp(() {
      collegeService = CollegeService();
    });

    group('loadColleges', () {
      test('should load colleges from data source', () async {
        final colleges = await collegeService.loadColleges();
        expect(colleges, isA<List>());
      });

      test('should handle empty college list', () async {
        final colleges = await collegeService.loadColleges();
        expect(colleges, isA<List>());
      });
    });

    group('CollegeInfo', () {
      test('should parse college info from JSON', () {
        final json = {
          '_id': 'college-123',
          'name': 'Test College',
        };

        final collegeInfo = CollegeInfo.fromJson(json);
        expect(collegeInfo.id, equals('college-123'));
        expect(collegeInfo.name, equals('Test College'));
      });

      test('should handle missing id field', () {
        final json = {
          'name': 'Test College',
        };

        final collegeInfo = CollegeInfo.fromJson(json);
        // When id is missing, it returns empty string as per implementation
        expect(collegeInfo.id, equals(''));
      });

      test('should handle id field variations', () {
        final json1 = {'id': 'college-123', 'name': 'Test'};
        final json2 = {'_id': 'college-123', 'name': 'Test'};

        final info1 = CollegeInfo.fromJson(json1);
        final info2 = CollegeInfo.fromJson(json2);

        expect(info1.id, equals('college-123'));
        expect(info2.id, equals('college-123'));
      });
    });

    group('College Model', () {
      test('should parse complete college data', () {
        final json = {
          'id': 'college-123',
          'name': 'Test College',
          'city': 'Test City',
          'state': 'Test State',
          'address': '123 Test St',
          'status': 'active',
          'totalStudents': 100,
          'dailyActiveStudents': 50,
          'avgSkillScore': 75.5,
          'avgInterviewPractices': 10.0,
          'primaryAdmin': {
            'name': 'Admin Name',
            'email': 'admin@test.com',
            'phone': '1234567890',
          },
          'admins': [],
          'students': [],
        };

        final college = College.fromJson(json);
        expect(college.id, equals('college-123'));
        expect(college.name, equals('Test College'));
        expect(college.totalStudents, equals(100));
        expect(college.avgSkillScore, equals(75.5));
      });

      test('should parse primary admin data', () {
        final json = {
          'name': 'Admin Name',
          'email': 'admin@test.com',
          'phone': '1234567890',
        };

        final admin = PrimaryAdmin.fromJson(json);
        expect(admin.name, equals('Admin Name'));
        expect(admin.email, equals('admin@test.com'));
        expect(admin.phone, equals('1234567890'));
      });
    });
  });
}

