import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class PaymentService {
  final Razorpay _razorpay = Razorpay();
  final AuthService _authService = AuthService();

  // Initialize Razorpay
  void initializeRazorpay({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  // Create Razorpay order
  Future<Map<String, dynamic>> createOrder({
    String? courseId,
    String? examId,
    String? examTitle,
    int? attemptNumber,
    bool? isRetake,
    String? packageId,
    String? slotId,
    Map<String, dynamic>? offerInfo,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();

      // Build request body matching backend expectations
      final requestBody = <String, dynamic>{};

      // courseId can be null for exam/package payments
      if (courseId != null && courseId.isNotEmpty) {
        requestBody['courseId'] = courseId;
      }

      if (examId != null) {
        requestBody['examId'] = examId;
      }
      if (examTitle != null) {
        requestBody['examTitle'] = examTitle;
      }
      if (attemptNumber != null) {
        requestBody['attemptNumber'] = attemptNumber;
      }
      if (isRetake != null) {
        requestBody['isRetake'] = isRetake;
      }
      if (packageId != null) {
        requestBody['packageId'] = packageId;
      }
      if (slotId != null) {
        requestBody['slotId'] = slotId;
      }
      if (offerInfo != null) {
        requestBody['offerInfo'] = offerInfo;
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.razorpayCreateOrder),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Backend returns: orderId, amount (in paise), currency, receipt, paymentId, chargedAmount (in rupees)
          // Note: backend doesn't return keyId, so we'll use EnvConfig fallback
          return {
            'success': true,
            'orderId': data['data']['orderId'],
            'amount': data['data']['amount'], // Already in paise from backend
            'currency': data['data']['currency'] ?? 'INR',
            'receipt': data['data']['receipt'],
            'paymentId': data['data']['paymentId'],
            'chargedAmount': data['data']['chargedAmount'], // In rupees
            // keyId is not returned by backend, will use EnvConfig fallback
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to create order');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Bad request';
        // Handle "already have access" messages
        if (message.toString().toLowerCase().contains('already have access')) {
          throw Exception(message);
        }
        throw Exception(message);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Resource not found');
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Access denied');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to create order (${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Verify payment
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http.post(
        Uri.parse(ApiEndpoints.razorpayVerifyPayment),
        headers: headers,
        body: json.encode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Payment verified successfully',
          };
        } else {
          throw Exception(data['message'] ?? 'Payment verification failed');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid payment signature');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Unauthorized access to payment record');
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Payment record not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Payment verification failed (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  // Open Razorpay payment
  void openPayment({
    required String orderId,
    required String keyId,
    required String name,
    required String description,
    required int amount,
    required String currency,
    required String prefillEmail,
    required String prefillContact,
    Map<String, dynamic>? notes,
  }) {
    final options = {
      'key': keyId,
      'amount': amount,
      'name': name,
      'description': description,
      'order_id': orderId,
      'currency': currency,
      'prefill': {'email': prefillEmail, 'contact': prefillContact},
      'notes': notes ?? {},
      'theme': {'color': '#6B5FFF'},
    };

    _razorpay.open(options);
  }

  // Dispose Razorpay
  void dispose() {
    _razorpay.clear();
  }
}
