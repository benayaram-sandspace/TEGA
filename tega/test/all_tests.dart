import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'core/config/env_config_test.dart' as env_config_test;
import 'core/constants/api_constants_test.dart' as api_constants_test;
import 'features/authentication/auth_repository_test.dart'
    as auth_repository_test;
import 'widgets/splash_screen_test.dart' as splash_screen_test;
import 'widgets/login_page_test.dart' as login_page_test;
import 'widgets/main_app_test.dart' as main_app_test;
import 'integration/auth_flow_test.dart' as auth_flow_test;

void main() {
  group('Core Tests', () {
    env_config_test.main();
    api_constants_test.main();
  });

  group('Feature Tests', () {
    auth_repository_test.main();
  });

  group('Widget Tests', () {
    splash_screen_test.main();
    login_page_test.main();
    main_app_test.main();
  });

  group('Integration Tests', () {
    auth_flow_test.main();
  });
}
