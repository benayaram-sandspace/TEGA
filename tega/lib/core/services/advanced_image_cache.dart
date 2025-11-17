import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Advanced image cache manager with memory and disk caching
class AdvancedImageCache {
  static final AdvancedImageCache _instance = AdvancedImageCache._internal();
  factory AdvancedImageCache() => _instance;
  AdvancedImageCache._internal();

  // Memory cache
  final Map<String, ui.Image> _memoryCache = {};
  final Map<String, DateTime> _memoryCacheTimes = {};

  // Configuration
  static const int maxMemoryCacheSize = 100; // max images in memory
  static const Duration memoryCacheDuration = Duration(hours: 1);
  static const Duration diskCacheDuration = Duration(days: 7);

  // Statistics
  int _memoryHits = 0;
  int _diskHits = 0;
  int _networkHits = 0;

  /// Get cache statistics
  Map<String, dynamic> get stats => {
        'memorySize': _memoryCache.length,
        'memoryHits': _memoryHits,
        'diskHits': _diskHits,
        'networkHits': _networkHits,
      };

  /// Get cached directory
  Future<Directory> get _cacheDir async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/image_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generate cache key from URL
  String _getCacheKey(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  /// Get image from memory cache
  ui.Image? _getFromMemory(String key) {
    if (!_memoryCache.containsKey(key)) return null;

    final cacheTime = _memoryCacheTimes[key];
    if (cacheTime != null &&
        DateTime.now().difference(cacheTime) > memoryCacheDuration) {
      _removeFromMemory(key);
      return null;
    }

    _memoryHits++;
    return _memoryCache[key];
  }

  /// Store image in memory cache
  void _storeInMemory(String key, ui.Image image) {
    // Implement LRU eviction if cache is full
    if (_memoryCache.length >= maxMemoryCacheSize) {
      final oldestKey = _memoryCacheTimes.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _removeFromMemory(oldestKey);
    }

    _memoryCache[key] = image;
    _memoryCacheTimes[key] = DateTime.now();
  }

  /// Remove image from memory cache
  void _removeFromMemory(String key) {
    _memoryCache[key]?.dispose();
    _memoryCache.remove(key);
    _memoryCacheTimes.remove(key);
  }

  /// Get image from disk cache
  Future<Uint8List?> _getFromDisk(String key) async {
    try {
      final dir = await _cacheDir;
      final file = File('${dir.path}/$key');

      if (!await file.exists()) return null;

      final stat = await file.stat();
      if (DateTime.now().difference(stat.modified) > diskCacheDuration) {
        await file.delete();
        return null;
      }

      _diskHits++;
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Store image in disk cache
  Future<void> _storeToDisk(String key, Uint8List bytes) async {
    try {
      final dir = await _cacheDir;
      final file = File('${dir.path}/$key');
      await file.writeAsBytes(bytes);
    } catch (e) {
      // Silently fail disk caching
    }
  }

  /// Download image from network
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        _networkHits++;
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert bytes to ui.Image
  Future<ui.Image?> _bytesToImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      return null;
    }
  }

  /// Get image with full caching pipeline
  Future<ui.Image?> getImage(String url) async {
    final key = _getCacheKey(url);

    // 1. Check memory cache
    final memoryImage = _getFromMemory(key);
    if (memoryImage != null) return memoryImage;

    // 2. Check disk cache
    final diskBytes = await _getFromDisk(key);
    if (diskBytes != null) {
      final image = await _bytesToImage(diskBytes);
      if (image != null) {
        _storeInMemory(key, image);
        return image;
      }
    }

    // 3. Download from network
    final networkBytes = await _downloadImage(url);
    if (networkBytes != null) {
      final image = await _bytesToImage(networkBytes);
      if (image != null) {
        _storeInMemory(key, image);
        await _storeToDisk(key, networkBytes);
        return image;
      }
    }

    return null;
  }

  /// Preload images in background
  Future<void> preloadImages(List<String> urls) async {
    for (final url in urls) {
      unawaited(getImage(url));
    }
  }

  /// Clear memory cache
  void clearMemory() {
    for (final image in _memoryCache.values) {
      image.dispose();
    }
    _memoryCache.clear();
    _memoryCacheTimes.clear();
  }

  /// Clear disk cache
  Future<void> clearDisk() async {
    try {
      final dir = await _cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear all caches
  Future<void> clearAll() async {
    clearMemory();
    await clearDisk();
  }

  /// Get disk cache size
  Future<int> getDiskCacheSize() async {
    try {
      final dir = await _cacheDir;
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}

/// Cached network image widget
class CachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  ui.Image? _image;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final image = await AdvancedImageCache().getImage(widget.imageUrl);
      if (mounted) {
        setState(() {
          _image = image;
          _isLoading = false;
          _hasError = image == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
    }

    if (_hasError || _image == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
    }

    return CustomPaint(
      size: Size(widget.width ?? double.infinity, widget.height ?? double.infinity),
      painter: _ImagePainter(_image!, widget.fit),
    );
  }

  @override
  void dispose() {
    // Don't dispose image here - it's managed by cache
    super.dispose();
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;

  _ImagePainter(this.image, this.fit);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    final FittedSizes fittedSizes = applyBoxFit(fit, src.size, dst.size);
    final Rect targetRect = Alignment.center.inscribe(fittedSizes.destination, dst);

    canvas.drawImageRect(image, src, targetRect, Paint());
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) => oldDelegate.image != image;
}

