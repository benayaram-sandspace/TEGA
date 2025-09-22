const String baseUrl = 'http://192.168.0.180:5000';

class ApiEndpoints {
  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';
  static const String logout = '$baseUrl/api/auth/logout';
  static const String colleges = '$baseUrl/api/colleges';
}
