import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String? profilePhotoUrl;
  final String? username;
  final String? firstName;
  final String? lastName;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const ProfilePictureWidget({
    super.key,
    this.profilePhotoUrl,
    this.username,
    this.firstName,
    this.lastName,
    this.radius = 20.0,
    this.onTap,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  bool _imageError = false;

  @override
  void didUpdateWidget(ProfilePictureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state if URL changes
    if (oldWidget.profilePhotoUrl != widget.profilePhotoUrl) {
      _imageError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials();
    final effectiveBorderColor = widget.borderColor ?? const Color(0xFF6B5FFF);
    
    // Determine if we should show image or initials
    final shouldShowImage = widget.profilePhotoUrl != null &&
        widget.profilePhotoUrl!.isNotEmpty &&
        !_imageError;

    Widget avatarWidget = CircleAvatar(
      radius: widget.radius,
      backgroundColor: const Color(0xFF6B5FFF).withOpacity(0.1),
      backgroundImage: shouldShowImage
          ? CachedNetworkImageProvider(widget.profilePhotoUrl!)
          : null,
      // Only set onBackgroundImageError when backgroundImage is not null
      onBackgroundImageError: shouldShowImage
          ? (exception, stackTrace) {
              // Handle image loading errors (404, network errors, etc.)
              if (mounted) {
                setState(() {
                  _imageError = true;
                });
              }
            }
          : null,
      child: !shouldShowImage
          ? Text(
              initials,
              style: TextStyle(
                fontSize: widget.radius * 0.6,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B5FFF),
              ),
            )
          : null,
    );

    if (widget.showBorder) {
      avatarWidget = Container(
        padding: EdgeInsets.all(widget.borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [effectiveBorderColor, effectiveBorderColor.withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveBorderColor.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: EdgeInsets.all(widget.borderWidth),
          child: avatarWidget,
        ),
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  String _getInitials() {
    // Try to get initials from firstName and lastName first
    if (widget.firstName != null && widget.lastName != null) {
      final firstInitial = widget.firstName!.isNotEmpty ? widget.firstName![0].toUpperCase() : '';
      final lastInitial = widget.lastName!.isNotEmpty ? widget.lastName![0].toUpperCase() : '';
      if (firstInitial.isNotEmpty && lastInitial.isNotEmpty) {
        return '$firstInitial$lastInitial';
      }
      if (firstInitial.isNotEmpty) return firstInitial;
      if (lastInitial.isNotEmpty) return lastInitial;
    }

    // Fallback to username/email
    final name = widget.username ?? 'U';
    if (name.isEmpty) return 'U';

    // Extract name from email if it's an email
    String extractedName = name;
    if (name.contains('@')) {
      extractedName = name.split('@')[0];
    }

    // Split by common separators and get first two words
    final words = extractedName
        .split(RegExp(r'[._\s]+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    // Return first letter of first two words
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }
}
