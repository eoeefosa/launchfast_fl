import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campuschow/utils/ui_utils.dart';

class UniversalImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image/') && imageUrl.contains('base64,')) {
      try {
        final base64String = imageUrl.split('base64,').last;
        return Image.memory(
          base64Decode(base64String),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Base64 Image load failed: $error');
            return _buildErrorWidget();
          },
        );
      } catch (e) {
        debugPrint('Base64 Image decoding failed: $e');
        return _buildErrorWidget();
      }
    }

    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    final optimizedUrl = UIUtils.optimizeCloudinaryUrl(imageUrl);

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) {
        debugPrint('Image load failed ($url): $error');
        return errorWidget ?? _buildErrorWidget();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withValues(alpha: 0.1),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 24),
      ),
    );
  }
}
