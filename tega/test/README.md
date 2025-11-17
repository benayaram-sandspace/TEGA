# TEGA Test Suite

This directory contains comprehensive test cases for the TEGA Flutter application.

## Test Structure

```
test/
├── core/
│   ├── config/
│   │   └── env_config_test.dart          # Environment configuration tests
│   ├── constants/
│   │   └── api_constants_test.dart       # API endpoints tests
│   └── services/
│       └── cache_services_test.dart      # Cache services tests
├── features/
│   ├── authentication/
│   │   ├── auth_repository_test.dart     # Authentication service tests
│   │   └── auth_flows_test.dart          # Authentication flow tests
│   ├── student_dashboard/
│   │   ├── student_dashboard_service_test.dart  # Student dashboard service tests
│   │   └── payment_service_test.dart     # Payment service tests
│   ├── admin_panel/
│   │   └── admin_repository_test.dart    # Admin repository tests
│   ├── college_panel/
│   │   └── college_repository_test.dart   # College repository tests
│   └── models/
│       └── model_validation_test.dart    # Model validation tests
├── widgets/
│   ├── splash_screen_test.dart           # Splash screen widget tests
│   ├── login_page_test.dart              # Login page widget tests
│   ├── main_app_test.dart                # Main app widget tests
│   ├── authentication/
│   │   ├── signup_page_test.dart         # Signup page tests
│   │   └── forgot_password_page_test.dart # Forgot password page tests
│   └── student/
│       └── student_home_page_test.dart    # Student home page tests
├── integration/
│   ├── auth_flow_test.dart               # Authentication flow integration tests
│   └── complete_user_flows_test.dart     # Complete user flow tests
├── error_handling/
│   └── error_scenarios_test.dart         # Error handling and edge cases
├── business_logic/
│   ├── course_enrollment_logic_test.dart      # Course enrollment business rules
│   ├── payment_processing_logic_test.dart      # Payment processing business rules
│   ├── exam_registration_logic_test.dart      # Exam registration business rules
│   ├── access_control_logic_test.dart         # Access control business rules
│   ├── progress_tracking_logic_test.dart      # Progress tracking business rules
│   └── offer_discount_logic_test.dart          # Offer and discount business rules
├── helpers/
│   └── test_helpers.dart                 # Test utility functions
├── all_tests.dart                         # Test suite runner
└── widget_test.dart                       # Basic app smoke test
```

## Running Tests

### Run all tests

```bash
flutter test
```

### Run specific test file

```bash
flutter test test/core/config/env_config_test.dart
```

### Run tests with coverage

```bash
flutter test --coverage
```

### Run tests in watch mode (auto-rerun on changes)

```bash
flutter test --watch
```

## Test Coverage

### Unit Tests

- **Core Utilities**: Environment configuration, API constants
- **Authentication**: User model, AuthService, API responses
- **Models**: User parsing, serialization, role handling

### Widget Tests

- **Splash Screen**: Basic rendering, navigation logic
- **Login Page**: Form fields, button presence, UI structure
- **Main App**: Theme configuration, app initialization

### Integration Tests

- **Authentication Flow**: Session management, token handling, role checks

## Test Statistics

- **Total Tests**: 291 ✅
- **Passing**: 291
- **Failing**: 0
- **Coverage Areas**:
  - Core configuration and constants
  - Authentication service and models
  - Student dashboard services
  - Payment services
  - Admin panel repositories
  - College panel features
  - Cache services
  - Key UI components (authentication, student dashboard)
  - User session management
  - Error handling and edge cases
  - Model validation
  - Complete user flows
  - **Business Logic** (101 tests):
    - Course enrollment logic
    - Payment processing logic
    - Exam registration logic
    - Access control logic
    - Progress tracking logic
    - Offer and discount logic

## Test Helpers

The `test_helpers.dart` file provides utility functions for:

- Creating mock users (student, admin, principal)
- Clearing SharedPreferences
- Custom matchers for email and password validation

## Writing New Tests

When adding new features, follow these guidelines:

1. **Unit Tests**: Test business logic, models, and services
2. **Widget Tests**: Test UI components and user interactions
3. **Integration Tests**: Test complete user flows

### Example Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureName', () {
    setUp(() {
      // Setup code
    });

    test('should do something', () {
      // Test implementation
      expect(actual, expected);
    });
  });
}
```

## Notes

- Tests use mock SharedPreferences to avoid side effects
- Environment config tests handle missing .env files gracefully
- Widget tests use flexible finders to accommodate different UI implementations
- All tests are designed to be independent and can run in any order
