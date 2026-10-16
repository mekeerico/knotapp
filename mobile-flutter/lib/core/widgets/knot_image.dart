import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class KnotImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final String fallbackUrl;

  const KnotImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
    this.fallbackUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800',
  });

  static String resolveUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    final trimmed = raw.trim();
    if (trimmed.startsWith('/uploads/')) {
      const apiBase = String.fromEnvironment('API_URL', defaultValue: 'http://knotconnect.duckdns.org:8080');
      return '$apiBase$trimmed';
    }
    return trimmed;
  }

  static ImageProvider resolveProvider(String? raw, {String? fallback}) {
    final effectiveFallback = fallback ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800';
    if (raw == null || raw.trim().isEmpty) {
      return NetworkImage(effectiveFallback);
    }
    final url = raw.trim();
    if (url.startsWith('data:image')) {
      try {
        final b64 = url.contains('base64,') ? url.split('base64,')[1] : url;
        return MemoryImage(base64Decode(b64));
      } catch (_) {
        return NetworkImage(effectiveFallback);
      }
    }
    if (url.startsWith('/uploads/')) {
      const apiBase = String.fromEnvironment('API_URL', defaultValue: 'http://knotconnect.duckdns.org:8080');
      return NetworkImage('$apiBase$url');
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImageProvider(url);
    }
    if (File(url).existsSync()) {
      return FileImage(File(url));
    }
    return NetworkImage(effectiveFallback);
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildContent();

    if (isCircle) {
      imageWidget = ClipOval(child: imageWidget);
    } else if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return SizedBox(
      width: width,
      height: height,
      child: imageWidget,
    );
  }

  Widget _buildContent() {
    final url = resolveUrl(imageUrl);

    if (url.isEmpty) {
      return _buildFallback();
    }

    if (url.startsWith('data:image')) {
      try {
        final b64 = url.contains('base64,') ? url.split('base64,')[1] : url;
        return Image.memory(
          base64Decode(b64),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } catch (_) {
        return _buildFallback();
      }
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, _) => Container(
          color: AppColors.darkSlate,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.champagneGold),
            ),
          ),
        ),
        errorWidget: (context, _, __) => _buildFallback(),
      );
    }

    final file = File(url);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return CachedNetworkImage(
      imageUrl: fallbackUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => Container(color: AppColors.darkSlate),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.darkSlate,
        child: const Icon(Icons.person, color: AppColors.textSubtle, size: 40),
      ),
    );
  }
}
