import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

void showImageViewer(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      // transitionDuration: Duration(milliseconds: 100), // no animation
      pageBuilder: (_, __, ___) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null &&
                      details.primaryDelta! > 20) {
                    Navigator.of(context).pop();
                  }
                },
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.black),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.0,
                  loadingBuilder: (context, _) =>
                      const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.error, color: Colors.white)),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
