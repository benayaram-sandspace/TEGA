import 'dart:async';
import 'dart:collection';
import 'package:http/http.dart' as http;

/// Connection optimizer for better network performance
class ConnectionOptimizer {
  static final ConnectionOptimizer _instance = ConnectionOptimizer._internal();
  factory ConnectionOptimizer() => _instance;
  ConnectionOptimizer._internal();

  // HTTP client with keep-alive
  final http.Client _client = http.Client();

  // Request queue for offline mode
  final Queue<_QueuedRequest> _requestQueue = Queue();
  bool _isOnline = true;

  // Request batching
  final Map<String, List<Completer<http.Response>>> _batchedRequests = {};
  final Map<String, Timer> _batchTimers = {};

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration batchWindow = Duration(milliseconds: 300);

  // Network status listeners
  final List<Function(bool)> _networkListeners = [];

  /// Get the shared HTTP client
  http.Client get client => _client;

  /// Make request with auto-retry and offline queue
  Future<http.Response> request(
    String method,
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    bool enableRetry = true,
    bool queueIfOffline = true,
  }) async {
    if (!_isOnline && queueIfOffline) {
      return _queueRequest(method, url, headers: headers, body: body);
    }

    return _makeRequest(
      method,
      url,
      headers: headers,
      body: body,
      retries: enableRetry ? maxRetries : 0,
    );
  }

  /// Internal request method with retry logic
  Future<http.Response> _makeRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    int retries = 0,
  }) async {
    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(url, headers: headers)
              .timeout(const Duration(seconds: 30));
          break;
        case 'POST':
          response = await _client
              .post(url, headers: headers, body: body)
              .timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await _client
              .put(url, headers: headers, body: body)
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await _client
              .delete(url, headers: headers)
              .timeout(const Duration(seconds: 30));
          break;
        case 'PATCH':
          response = await _client
              .patch(url, headers: headers, body: body)
              .timeout(const Duration(seconds: 30));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return response;
    } catch (e) {
      if (retries > 0) {
        await Future.delayed(retryDelay);
        return _makeRequest(
          method,
          url,
          headers: headers,
          body: body,
          retries: retries - 1,
        );
      }
      rethrow;
    }
  }

  /// Queue request for when connection is restored
  Future<http.Response> _queueRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    final completer = Completer<http.Response>();
    _requestQueue.add(
      _QueuedRequest(
        method: method,
        url: url,
        headers: headers,
        body: body,
        completer: completer,
      ),
    );
    return completer.future;
  }

  /// Process queued requests
  Future<void> _processQueue() async {
    while (_requestQueue.isNotEmpty && _isOnline) {
      final request = _requestQueue.removeFirst();
      try {
        final response = await _makeRequest(
          request.method,
          request.url,
          headers: request.headers,
          body: request.body,
        );
        request.completer.complete(response);
      } catch (e) {
        request.completer.completeError(e);
      }
    }
  }

  /// Batch similar requests together
  Future<http.Response> batchRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final key = '$method:$url';

    final completer = Completer<http.Response>();

    if (_batchedRequests.containsKey(key)) {
      _batchedRequests[key]!.add(completer);
    } else {
      _batchedRequests[key] = [completer];

      _batchTimers[key] = Timer(batchWindow, () async {
        final completers = _batchedRequests[key]!;
        _batchedRequests.remove(key);
        _batchTimers.remove(key);

        try {
          final response = await _makeRequest(method, url, headers: headers);
          for (final c in completers) {
            c.complete(response);
          }
        } catch (e) {
          for (final c in completers) {
            c.completeError(e);
          }
        }
      });
    }

    return completer.future;
  }

  /// Prefetch resources in background
  Future<void> prefetch(List<Uri> urls) async {
    for (final url in urls) {
      unawaited(
        _client.get(url).catchError((error) {
          // Silently handle prefetch errors
          return http.Response('', 500);
        }),
      );
    }
  }

  /// Update network status and trigger listeners
  void updateNetworkStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _notifyNetworkListeners(isOnline);

      // Process queue if coming back online
      if (isOnline) {
        _processQueue();
      }
    }
  }

  /// Add network status listener
  void addNetworkListener(Function(bool) listener) {
    _networkListeners.add(listener);
  }

  /// Remove network status listener
  void removeNetworkListener(Function(bool) listener) {
    _networkListeners.remove(listener);
  }

  /// Notify all network listeners
  void _notifyNetworkListeners(bool isOnline) {
    for (final listener in _networkListeners) {
      listener(isOnline);
    }
  }

  /// Get connection stats
  Map<String, dynamic> get stats => {
    'isOnline': _isOnline,
    'queueSize': _requestQueue.length,
    'activeBatches': _batchedRequests.length,
    'networkListeners': _networkListeners.length,
  };

  /// Clear all queues and batches
  void clearQueues() {
    _requestQueue.clear();
    _batchedRequests.clear();
    for (final timer in _batchTimers.values) {
      timer.cancel();
    }
    _batchTimers.clear();
  }

  /// Dispose resources
  void dispose() {
    _client.close();
    clearQueues();
    _networkListeners.clear();
  }
}

/// Internal class for queued requests
class _QueuedRequest {
  final String method;
  final Uri url;
  final Map<String, String>? headers;
  final dynamic body;
  final Completer<http.Response> completer;

  _QueuedRequest({
    required this.method,
    required this.url,
    this.headers,
    this.body,
    required this.completer,
  });
}
