const String baseUrl = 'http://10.0.2.2:5000';

class ApiEndpoints {
  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';
  static const String logout = '$baseUrl/api/auth/logout';
  static const String colleges = '$baseUrl/api/colleges';
}
