import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class KnotImage extends StatelessWidget {
  static final Map<int, Uint8List> _base64Cache = {};

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final String? fallbackUrl;

  const KnotImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
    this.fallbackUrl,
  });

  static Uint8List _decodeCached(String url) {
    final key = url.hashCode;
    final cached = _base64Cache[key];
    if (cached != null) return cached;
    final b64 = url.contains('base64,') ? url.split('base64,')[1] : url;
    final bytes = base64Decode(b64);
    if (_base64Cache.length > 60) {
      _base64Cache.remove(_base64Cache.keys.first);
    }
    _base64Cache[key] = bytes;
    return bytes;
  }

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
    if (raw == null || raw.trim().isEmpty) {
      if (fallback != null && fallback.isNotEmpty) {
        return CachedNetworkImageProvider(fallback);
      }
      return const AssetImage('assets/icons/app_icon.png');
    }
    final url = raw.trim();
    if (url.startsWith('data:image')) {
      try {
        return MemoryImage(_decodeCached(url));
      } catch (_) {
        if (fallback != null && fallback.isNotEmpty) {
          return CachedNetworkImageProvider(fallback);
        }
        return const AssetImage('assets/icons/app_icon.png');
      }
    }
    if (url.startsWith('/uploads/')) {
      const apiBase = String.fromEnvironment('API_URL', defaultValue: 'http://knotconnect.duckdns.org:8080');
      return CachedNetworkImageProvider('$apiBase$url');
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImageProvider(url);
    }
    if (File(url).existsSync()) {
      return FileImage(File(url));
    }
    if (fallback != null && fallback.isNotEmpty) {
      return CachedNetworkImageProvider(fallback);
    }
    return const AssetImage('assets/icons/app_icon.png');
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
        return Image.memory(
          _decodeCached(url),
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
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
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 80),
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
    if (fallbackUrl != null && fallbackUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: fallbackUrl!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => Container(color: AppColors.darkSlate),
        errorWidget: (_, __, ___) => _buildPlaceholderBox(),
      );
    }
    return _buildPlaceholderBox();
  }

  Widget _buildPlaceholderBox() {
    return Container(
      color: AppColors.darkSlate,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        color: AppColors.champagneGold.withValues(alpha: 0.45),
        size: width != null ? (width! * 0.4).clamp(18.0, 48.0) : 32.0,
      ),
    );
  }
}
