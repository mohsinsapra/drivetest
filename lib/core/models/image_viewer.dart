import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';

void showImageViewer(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: animation,
        child: _ImageViewerPage(imageUrl: imageUrl),
      ),
    ),
  );
}

class _ImageViewerPage extends StatefulWidget {
  final String imageUrl;
  const _ImageViewerPage({required this.imageUrl});

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage>
    with SingleTickerProviderStateMixin {
  final PhotoViewScaleStateController _scaleStateController =
      PhotoViewScaleStateController();

  // Drag-to-dismiss state
  double _dragOffset = 0;
  bool _isZoomed = false;

  // Spring-back animation
  late final AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _springAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );

    _scaleStateController.outputScaleStateStream.listen((state) {
      final zoomed = state != PhotoViewScaleState.initial;
      if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
    });
  }

  @override
  void dispose() {
    _scaleStateController.dispose();
    _springController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isZoomed) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset.abs() > 100 || velocity.abs() > 600) {
      Navigator.of(context).pop();
    } else {
      // Spring back
      _springAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
      );
      _springController.forward(from: 0).then((_) {
        if (mounted) setState(() => _dragOffset = 0);
      });
      _springAnimation.addListener(() {
        if (mounted) setState(() => _dragOffset = _springAnimation.value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dismissProgress = (_dragOffset.abs() / 250).clamp(0.0, 1.0);
    final bgOpacity = 1.0 - dismissProgress * 0.85;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: _isZoomed ? null : _onDragUpdate,
          onVerticalDragEnd: _isZoomed ? null : _onDragEnd,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Stack(
              children: [
                PhotoView(
                  imageProvider: NetworkImage(widget.imageUrl),
                  scaleStateController: _scaleStateController,
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.transparent),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 5.0,
                  initialScale: PhotoViewComputedScale.contained,
                  enableRotation: false,
                  loadingBuilder: (_, event) => Center(
                    child: CircularProgressIndicator(
                      value: event?.expectedTotalBytes != null
                          ? event!.cumulativeBytesLoaded /
                              event.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  ),
                  errorBuilder: (ctx, __, ___) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image,
                            color: Colors.white54, size: 48),
                        const SizedBox(height: 8),
                        Text(Translations.of(ctx).image_viewer_load_error,
                            style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),

                // Close button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),

                // Swipe hint
                if (_dragOffset.abs() < 8)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        Translations.of(context).image_viewer_swipe_to_close,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
