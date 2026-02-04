import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lpl_auction_app/services/api_service.dart';

class CustomNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CustomNetworkImage> createState() => _CustomNetworkImageState();
}

class _CustomNetworkImageState extends State<CustomNetworkImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _fetchImage();
    }
  }

  @override
  void didUpdateWidget(covariant CustomNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      if (kIsWeb) {
        _fetchImage();
      }
    }
  }

  String _getProxiedUrl(String url) {
    if (kIsWeb) {
      // If it's an external URL, proxy it to avoid CORS
      if (url.startsWith('http') && !url.startsWith(ApiService.baseUrl)) {
        // Double encode the component to ensure it passes safely as a query param
        return '${ApiService.baseUrl}/proxy?url=${Uri.encodeComponent(url)}';
      }
    }
    return url;
  }

  Future<void> _fetchImage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final effectiveUrl = _getProxiedUrl(widget.imageUrl);
      final headers = <String, String>{};

      // Add headers if hitting our API (directly or via proxy)
      if (effectiveUrl.startsWith(ApiService.baseUrl) ||
          effectiveUrl.startsWith(ApiService.baseUrl.replaceAll('/api', ''))) {
        headers['ngrok-skip-browser-warning'] = 'true';
      }

      final response =
          await http.get(Uri.parse(effectiveUrl), headers: headers);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        debugPrint(
            'Image fetch failed: ${response.statusCode} for $effectiveUrl');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Image fetch error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    if (kIsWeb) {
      if (_isLoading) {
        return _buildPlaceholder();
      }
      if (_hasError || _imageBytes == null) {
        return widget.errorWidget ?? _buildDefaultError();
      }
      return Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            widget.errorWidget ?? _buildDefaultError(),
      );
    }

    // Mobile / Desktop fallback to standard Image.network
    final effectiveUrl = _getProxiedUrl(widget.imageUrl);
    // Note: Headers are ignored on Web by Image.network, but we handled Web above.
    // On Mobile/Desktop, I/O client supports headers.
    Map<String, String>? headers;
    if (effectiveUrl.startsWith(ApiService.baseUrl) ||
        effectiveUrl.startsWith(ApiService.baseUrl.replaceAll('/api', ''))) {
      headers = {'ngrok-skip-browser-warning': 'true'};
    }

    return Image.network(
      effectiveUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.cover,
      headers: headers,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image Load Error: $error for $effectiveUrl');
        return widget.errorWidget ?? _buildDefaultError();
      },
    );
  }

  Widget _buildPlaceholder([ImageChunkEvent? loadingProgress]) {
    return widget.placeholder ??
        Center(
          child: CircularProgressIndicator(
            value: loadingProgress != null &&
                    loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
  }

  Widget _buildDefaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
