import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance optimization utilities for smooth UX

/// Debouncer - Delays execution until user stops action
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler - Limits execution frequency
class Throttler {
  final Duration duration;
  bool _isReady = true;

  Throttler({required this.duration});

  void call(VoidCallback action) {
    if (!_isReady) return;

    _isReady = false;
    action();
    Timer(duration, () => _isReady = true);
  }
}

/// Frame scheduling utilities
class FrameScheduler {
  /// Schedule callback after current frame
  static void scheduleFrame(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());
  }

  /// Schedule callback on next frame
  static void scheduleNextFrame(VoidCallback callback) {
    SchedulerBinding.instance.scheduleFrameCallback((_) => callback());
  }

  /// Batch multiple operations into single frame
  static void batchOperations(List<VoidCallback> operations) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      for (final op in operations) {
        op();
      }
    });
  }
}

/// Keep alive wrapper for list items
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({
    super.key,
    required this.child,
  });

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Smart scroll controller with performance optimizations
class SmartScrollController extends ScrollController {
  final Duration debounce;
  Timer? _debounceTimer;
  final List<VoidCallback> _listeners = [];

  SmartScrollController({
    this.debounce = const Duration(milliseconds: 100),
  });

  void addDebouncedListener(VoidCallback listener) {
    _listeners.add(listener);
    addListener(_onScroll);
  }

  void _onScroll() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      for (final listener in _listeners) {
        listener();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _listeners.clear();
    super.dispose();
  }
}

/// Pagination helper for lists
class PaginationHelper {
  final int pageSize;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  PaginationHelper({this.pageSize = 20});

  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  Future<List<T>> loadPage<T>(
    Future<List<T>> Function(int page, int pageSize) fetchFunction,
  ) async {
    if (_isLoading || !_hasMore) return [];

    _isLoading = true;
    try {
      final items = await fetchFunction(_currentPage, pageSize);
      _currentPage++;
      _hasMore = items.length >= pageSize;
      return items;
    } finally {
      _isLoading = false;
    }
  }

  void reset() {
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
  }
}

/// Lazy loading builder
class LazyLoader<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext, T) builder;
  final Widget? placeholder;
  final Widget Function(BuildContext, Object)? errorBuilder;

  const LazyLoader({
    super.key,
    required this.loader,
    required this.builder,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  State<LazyLoader<T>> createState() => _LazyLoaderState<T>();
}

class _LazyLoaderState<T> extends State<LazyLoader<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    // Delay loading until after first frame
    _future = Future.delayed(Duration.zero, widget.loader);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.hasData) {
          return widget.builder(context, snapshot.data as T);
        }

        return widget.placeholder ??
            const Center(child: CircularProgressIndicator());
      },
    );
  }
}

/// Optimized list view with built-in performance features
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      cacheExtent: 500, // Cache 500 pixels ahead
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
    );
  }
}

/// Optimized grid view
class OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.childAspectRatio = 1.0,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      cacheExtent: 500,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
    );
  }
}

