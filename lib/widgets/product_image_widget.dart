import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final String baseUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ProductImageWidget({
    super.key,
    required this.imageUrl,
    required this.baseUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageContent = _buildImageContent();

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }
    return imageContent;
  }

  Widget _buildImageContent() {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildPlaceholder();
    }

    final trimmedUrl = imageUrl!.trim();

    // Local assets handling
    if (trimmedUrl.startsWith('assets/')) {
      return Image.asset(
        trimmedUrl,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // Network image handling
    String fullUrl;
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      fullUrl = trimmedUrl;
    } else {
      final cleanPath = trimmedUrl.startsWith('/') ? trimmedUrl.substring(1) : trimmedUrl;
      final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      fullUrl = '$cleanBase/$cleanPath';
    }

    return Image.network(
      fullUrl,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppColors.bgMiddle,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryAccent,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.bgMiddle,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.style_outlined,
            color: AppColors.primaryAccent,
            size: 38,
          ),
          SizedBox(height: 4),
          Text(
            'Bola Designs',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
