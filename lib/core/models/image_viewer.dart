import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';

/// Opens a full-screen gallery viewer.
///
/// [images]     — list of image URLs.
/// [initialIndex] — which image to start on.
/// [titles]     — optional per-image labels (parallel to [images]).
///               When provided, the title for the currently visible image
///               is shown below it, so each tab's name appears as you swipe.
/// [tabTexts]   — optional per-image text bodies (parallel to [images]).
///               Shown as a scrollable panel so the user never has to close
///               the viewer to read the tab's text content.
void showImageViewer(
  BuildContext context,
  List<String> images, {
  int initialIndex = 0,
  List<String>? titles,
  List<String>? tabTexts,
}) {
  if (images.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: animation,
        child: _ImageViewerPage(
          images: images,
          initialIndex: initialIndex,
          titles: titles,
          tabTexts: tabTexts,
        ),
      ),
    ),
  );
}

class _ImageViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final List<String>? titles;
  final List<String>? tabTexts;

  const _ImageViewerPage({
    required this.images,
    required this.initialIndex,
    this.titles,
    this.tabTexts,
  });

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  final _noScreenshot = kIsWeb ? null : NoScreenshot.instance;
  late final List<PhotoViewScaleStateController> _scaleControllers;

  double _dragOffset = 0;
  bool _isZoomed = false;
  int _pointerCount = 0;

  late final AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    if (AppStorage.allowScreenshots()) {
      _noScreenshot?.screenshotOn();
    } else {
      _noScreenshot?.screenshotOff();
    }
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    _scaleControllers = List.generate(
      widget.images.length,
      (_) => PhotoViewScaleStateController(),
    );
    for (final ctrl in _scaleControllers) {
      ctrl.outputScaleStateStream.listen((state) {
        final zoomed = state != PhotoViewScaleState.initial;
        if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
      });
    }

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _springAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    for (final ctrl in _scaleControllers) {
      ctrl.dispose();
    }
    _springController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isZoomed = false;
    });
  }

  bool get _dragBlocked => _isZoomed || _pointerCount > 1;

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragBlocked) return;
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragBlocked) {
      if (_dragOffset != 0) setState(() => _dragOffset = 0);
      return;
    }
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset.abs() > 100 || velocity.abs() > 600) {
      Navigator.of(context).pop();
    } else {
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

  String? get _currentTitle {
    final t = widget.titles;
    if (t == null || _currentIndex >= t.length) return null;
    final v = t[_currentIndex];
    return v.isNotEmpty ? v : null;
  }

  String? get _currentTabText {
    final tt = widget.tabTexts;
    if (tt == null || _currentIndex >= tt.length) return null;
    final v = tt[_currentIndex];
    return v.isNotEmpty ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final dismissProgress = (_dragOffset.abs() / 250).clamp(0.0, 1.0);
    final bgOpacity = 1.0 - dismissProgress * 0.85;
    final hasText = _currentTabText != null;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      body: SafeArea(
        child: Listener(
          // Rebuild GestureDetector immediately on second finger down so the
          // drag recognizer exits the arena before PhotoView's scale recognizer.
          onPointerDown: (_) => setState(() => _pointerCount++),
          onPointerUp: (_) => setState(() => _pointerCount--),
          onPointerCancel: (_) => setState(() => _pointerCount--),
          child: GestureDetector(
            onVerticalDragUpdate: _dragBlocked ? null : _onDragUpdate,
            onVerticalDragEnd: _dragBlocked ? null : _onDragEnd,
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Column(
                children: [
                  // ── Image gallery ────────────────────────────────────────
                  Expanded(
                    child: Stack(
                      children: [
                        PhotoViewGallery.builder(
                          pageController: _pageController,
                          itemCount: widget.images.length,
                          onPageChanged: _onPageChanged,
                          scrollPhysics: _isZoomed
                              ? const NeverScrollableScrollPhysics()
                              : const ClampingScrollPhysics(),
                          backgroundDecoration:
                              const BoxDecoration(color: Colors.transparent),
                          builder: (ctx, i) => PhotoViewGalleryPageOptions(
                            imageProvider:
                                CachedNetworkImageProvider(widget.images[i]),
                            scaleStateController: _scaleControllers[i],
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 5.0,
                            initialScale: PhotoViewComputedScale.contained,
                            errorBuilder: (ctx, __, ___) => Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.broken_image,
                                      color: Colors.white54, size: 48),
                                  const SizedBox(height: 8),
                                  Text(
                                    Translations.of(ctx)
                                        .image_viewer_load_error,
                                    style:
                                        const TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          loadingBuilder: (_, event) => Center(
                            child: CircularProgressIndicator(
                              value: event?.expectedTotalBytes != null
                                  ? event!.cumulativeBytesLoaded /
                                      event.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
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
                                child: Icon(Icons.close,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ),

                        // Bottom bar: title + dots + swipe hint (only when no
                        // text panel below — otherwise shown inside the panel)
                        if (!hasText)
                          Positioned(
                            bottom: 24,
                            left: 0,
                            right: 0,
                            child: _BottomBar(
                              title: _currentTitle,
                              imageCount: widget.images.length,
                              currentIndex: _currentIndex,
                              dragOffset: _dragOffset,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Tab text panel ───────────────────────────────────────
                  if (hasText)
                    _TextPanel(
                      title: _currentTitle,
                      text: _currentTabText!,
                      imageCount: widget.images.length,
                      currentIndex: _currentIndex,
                      dragOffset: _dragOffset,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String? title;
  final int imageCount;
  final int currentIndex;
  final double dragOffset;

  const _BottomBar({
    required this.title,
    required this.imageCount,
    required this.currentIndex,
    required this.dragOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (imageCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imageCount, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == currentIndex ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == currentIndex ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        if (dragOffset.abs() < 8)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              Translations.of(context).image_viewer_swipe_to_close,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _TextPanel extends StatelessWidget {
  final String? title;
  final String text;
  final int imageCount;
  final int currentIndex;
  final double dragOffset;

  const _TextPanel({
    required this.title,
    required this.text,
    required this.imageCount,
    required this.currentIndex,
    required this.dragOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xDD1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 36,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (imageCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BottomBar(
                title: null,
                imageCount: imageCount,
                currentIndex: currentIndex,
                dragOffset: dragOffset,
              ),
            ),
        ],
      ),
    );
  }
}
